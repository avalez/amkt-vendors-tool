require "net/https"
require "uri"

class LicensesController < ApplicationController
  def defaults
    @fromDate = Date.new(2012,04,28)
    @toDate = Date.new(2012,12,28)
    if (session[:fromDate] && session[:toDate])
      @fromDate = date session[:fromDate]
      @toDate = date session[:toDate]
    end
    @all_editions = License.all_editions
    @current_action = action_name
  end
  def licenses
    defaults
    filter = {}
    if (session[:editions])
      filter['edition'] = session[:editions].keys
    end
    if (session[:fromDate] && session[:toDate])
      filter[:startDate] = @fromDate .. @toDate
    end
    @licenses = License.where(filter)
    if (session[:countries])
      @licenses = @licenses.joins(:technicalContactAddress).where('addresses.country' => session[:countries].keys)
    end
    if (session[:sort])
      @licenses = @licenses.order(session[:sort])
    end
    @licenses = @licenses.includes([:technicalContact, :technicalContactAddress])
    if block_given?
      @licenses = yield @licenses
    end
    if !session[:group_by]
      @licenses.map {|license| license['price'] = License.price license}
    end
  end

  def date param
    Date.civil(param[:year].to_i, param[:month].to_i, param[:day].to_i)
  end

  def update_session param
    if (params[param]) 
      session[param] = params[param]
    end
  end

  def restful
    if (params[:editions] != session[:editions] ||
        params[:countries] != session[:countries] ||
        params[:fromDate] != session[:fromDate] ||
        params[:toDate] != session[:toDate] ||
        params[:sort] != session[:sort] ||
        params[:group_by] != session[:group_by])
      redirect_to :action => action_name,
        :editions => session[:editions], :countries => session[:countries],
        :fromDate => session[:fromDate], :toDate => session[:toDate],
        :sort => session[:sort], :group_by => session[:group_by]
      return false
    else
      return true
    end
  end

  def restful_redirect
    redirect_to :action => params[:return_to],
      :editions => session[:editions], :countries => session[:countries],
      :fromDate => session[:fromDate], :toDate => session[:toDate],
      :sort => session[:sort], :group_by => session[:group_by]
  end

  def filter
    session[:editions] = params[:editions]
    session[:countries] = params[:countries]
    session[:fromDate] = params[:fromDate]
    session[:toDate] = params[:toDate]
    restful_redirect
  end

  def sort
    session[:sort] = params[:sort]
    restful_redirect
  end

  def group
    session[:group_by] = params[:group_by]
    restful_redirect
  end

  def index
    restful or return false
    licenses
    geo
    @sum = @licenses.reduce(0) {|sum, license| sum + (license['price'] || 0)}
    @all_countries = @geo.keys
  end

  def bought
    index or return
    @licenses = @licenses.find_all {|license| License.paid_licenseTypes.include? license['licenseType']}
    @licenses = @licenses.sort_by {|license| license['startDate']}
    render :action => 'index'
  end

  def notbought
    index or return
    @licenses_map = @licenses.reduce({}) do |m, license|
      organisationName = license['organisationName'] || 'N/A'
      licenses = m[organisationName] || []
      i = licenses.index {|l| l['edition'] == license['edition']}
      if (!i)
        license['count'] = 1
        licenses <<= license
      elsif licenses[i]['startDate'] < license['startDate']
        license['count'] = licenses[i]['count'] + 1
        licenses[i] = license
      else
        licenses[i]['count'] += 1
      end
      m[organisationName] = licenses
      m
    end
    @licenses_map = @licenses_map.select do |organisationName, licenses|
      licenses.index {|license| license['edition'] != 'Evaluation'} == nil
    end
    @licenses = @licenses_map.values.flatten 1
    @licenses = @licenses.find_all {|license| license['endDate'] <= '2012-08-31' && license['endDate'] >= '2012-08-01'}
    @licenses = @licenses.sort_by {|license| license['organisationName']} 
    @sum = 0
    render :action => 'index'
  end

  def pivot_licenses
    licenses
=begin
    do |query| 
      case session[:group_by]
      when 'week'
        if (Rails.env.production?)
          # http://stackoverflow.com/questions/7171561/strftime-in-sqlite-convert-to-postgres
          week = 'extract(week from date("licenses"."startDate"))'
          year = 'extract(year from date("licenses"."startDate"))'
        else
          week = 'strftime("%W", date(startDate))'
          year = 'strftime("%Y", date(startDate))'
        end
        query = query.select("edition, count(*) count, #{week} \"week\", #{year} \"year\"").group(:year, :week, :edition)
      else
        query
      end
    end
=end
    @total = Hash[@all_editions.map {|edition, price| [edition, 0]}]
    @pivot = @licenses.reduce({}) do |m, row|
      if session[:group_by]
        date = Date.parse row['startDate']
        startDate = Date.commercial date.year, date.cweek, 1
      else
        startDate = row['startDate']
      end
      record = m[startDate] || {}
      edition = row['edition']
      record[edition] = (row['count'] || 1) + (record[edition] || 0)
      m[startDate] = record
      @total[edition] += row['count'] || 1
      m
    end
  end

  def pivot
    restful
    pivot_licenses
  end

  def timeline
    respond_to do |format|
      format.html do
        restful
        defaults
        @all_editions = License.all_editions
      end
      format.json do
        pivot_licenses
        json = { :all_editions => session[:editions] || @all_editions,
          :pivot => @pivot}
        render :json => json
      end
    end
  end

  def geo_licenses
    licenses
    geo
  end

  def geo
    @geo = @licenses.reduce({}) do |m, row|
      country = row.technicalContactAddress.country || 'N/A'
      m[country] = 1 + (m[country] || 0)
      m
    end
    @geo = Hash[@geo.sort_by {|country, count| country}]
  end

  def geochart
    respond_to do |format|
      format.html do
        restful
        defaults
      end
      format.json do
        geo_licenses
        json = { :geo => @geo}
        render :json => json
      end
    end
  end

  def import
    @log = flash[:log]
    @vendor = flash[:vendor]
  end

  def get_licenses username, password
    uri = URI.parse("https://marketplace.atlassian.com/login")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({:redirect => '', :username => username, :password => password})
    response = http.request(request)
    if (/\/login\?/ =~ response['location'])
      return nil
    end

    cookie = response['set-cookie'].split(';')[0]
    uri = URI.parse("https://marketplace.atlassian.com/manage/vendors/120/licenseReport")
    request = Net::HTTP::Get.new(uri.request_uri, {'Cookie' => cookie})
    response = http.request(request)
    if (response.code == '200')
      response.body.force_encoding("UTF-8")
    else
      @log << response.code
      @log << response.body
    end
  end

  def do_import
    @log = Array.new
    @vendor = Hash.new
    contact = Contact.new params[:vendor]
    csv = get_licenses contact.email, contact.password
    #csv = File.read('licenseReport.csv')
    if (csv)
      @log << License.import(csv)
    else
      flash[:warning] = "Login incorrect"
    end
    flash[:log] = @log
    flash[:vendor] = contact
    redirect_to import_licenses_path
  end

  def show
    @license = License.find params[:id]
  end

  def edit
    @license = License.find params[:id]
  end

  def update
    @license = License.find params[:id]
    @license.update_attributes!(params[:license])
    flash[:notice] = "#{@license.licenseId} was successfully updated."
    redirect_to license_path(@license)
  end

end