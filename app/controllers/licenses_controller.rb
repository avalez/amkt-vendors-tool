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
    if (session[:c])
      @licenses = @licenses.joins(:technicalContactAddress).where('addresses.country' => session[:c].keys)
    end
    if (session[:sort])
      # otherwise column does not exist in postresql
      @licenses = @licenses.order('"licenses".'+"\"#{session[:sort]}\"")
    end
    @licenses = @licenses.includes([:technicalContact, :technicalContactAddress])
    if block_given?
      @licenses = yield @licenses
    end
    @licenses.map {|license| license['price'] = License.price license}
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
    update_session :editions
    update_session :c
    update_session :fromDate
    update_session :toDate
    update_session :sort
    update_session :group_by
    if (params[:editions] != session[:editions] ||
        params[:c] != session[:c] ||
        params[:fromDate] != session[:fromDate] ||
        params[:toDate] != session[:toDate] ||
        params[:sort] != session[:sort] ||
        params[:group_by] != session[:group_by])
      redirect_to :action => action_name,
        :editions => session[:editions], :c => session[:c],
        :fromDate => session[:fromDate], :toDate => session[:toDate],
        :sort => session[:sort], :group_by => session[:group_by]
      return false
    else
      return true
    end
  end

  def restful_redirect
    redirect_to :action => params[:return_to],
      :editions => session[:editions], :c => session[:c],
      :fromDate => session[:fromDate], :toDate => session[:toDate],
      :sort => session[:sort], :group_by => session[:group_by]
  end

  def filter
    session[:editions] = params[:editions]
    session[:c] = params[:c]
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
    @supported_countries = License.supported_countries.reject { |c, _| @all_countries.index(c) == nil}
  end

  def bought
    index or return
    @licenses = @licenses.find_all {|license| License.paid_licenseTypes.index(license['licenseType'])}
    @licenses = @licenses.sort_by {|license| license['startDate']}
    render :action => 'index'
  end

  class OrganisationNameOrTechnicalEmailKey
    attr_reader :organisationName
    attr_reader :technicalEmail

    def initialize organisationName, technicalEmail, hashArray
      @organisationName = organisationName
      @technicalEmail = technicalEmail
      @hashArray = hashArray
    end

    def == other
       self.organisationName == other.organisationName ||
         self.technicalEmail == other.technicalEmail
    end
    
    def eql? other
      return self == other
    end
    
    def hash
      i = @hashArray.index self 
      if !i
        i = @hashArray.size
        @hashArray[i] = self
      end
      return i
    end
  end

  def notbought
    index or return
    hashArray = Array.new
    @licenses_map = @licenses.reduce({}) do |m, license|
      organisationName = license.organisationName || 'N/A'
      technicalEmail = license.technicalContact.email || 'N/A'
      key = OrganisationNameOrTechnicalEmailKey.new organisationName, technicalEmail, hashArray
      licenses = m[key] || []
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
      m[key] = licenses
      m
    end
    @licenses_map = @licenses_map.select do |organisationName, licenses|
      licenses.index {|license| license['edition'] != 'Evaluation'} == nil
    end
    @licenses = @licenses_map.values.flatten 1
    @licenses = @licenses.find_all {|license| license['endDate'] <= '2012-10-31' && license['endDate'] >= '2012-10-01'}
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
    @amount = Hash[@all_editions.map {|edition, price| [edition, 0]}]
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
      @amount[edition] += row['price']
      m
    end
  end

  def pivot
    respond_to do |format|
      format.html do
        restful
        pivot_licenses
      end
      format.json do
        pivot_licenses
        json = { :total => @total, :amount => @amount}
        render :json => json
      end
    end
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
    @vendor = flash[:vendor]
    @log = flash[:log] || Array.new
    if env['SERVER_SOFTWARE'] !~ /Unicorn/
      import_func flash[:amkt_cookie] {|log| @log = log}
      flash.delete :amkt_cookie
    end
    # see https://github.com/rails/rails/blob/master/actionpack/lib/action_cont
    # not possible with haml
    #render :stream => true
  end

  def import_func amkt_cookie
    if amkt_cookie
      csv = get_licenses amkt_cookie
      #csv = File.read('licenseReport.csv')
      if (csv)
        yield License.import(csv)
      end
    end
  end

  def import_stream
    amkt_cookie = params[:amkt_cookie]
    self.response.headers['Last-Modified'] = Time.now.to_s
    self.response_body = Enumerator.new do |y|
      import_func amkt_cookie do |log|
        log.each do |license|
          y << '<li>' + license.to_s.gsub(/</, '&lt;').gsub(/>/,'&gt;') + '</li>'
        end
      end
    end
  end

  def amkt_http uri
    proxy_addr = nil
    proxy_port = nil
    proxy_url = ENV['https_proxy']
    if (proxy_url)
      proxy = URI.parse(proxy_url)
      proxy_addr = proxy.host
      proxy_port = proxy.port
    end
    http = Net::HTTP.start(uri.host, uri.port, proxy_addr, proxy_port,
      :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE)
    http
  end

  def amkt_authenticate username, password
    uri = URI.parse("https://marketplace.atlassian.com/login")
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({:redirect => '', :username => username, :password => password})
    response = amkt_http(uri).request(request)
    auth = (/\/login\W/ !~ response['location'])
    if auth && block_given?
      yield response['set-cookie'].split(';')[0]
    end
    auth
  end
  
  def get_licenses cookie
    uri = URI.parse("https://marketplace.atlassian.com/manage/vendors/120/licenseReport")
    request = Net::HTTP::Get.new(uri.request_uri, {'Cookie' => cookie})
    response = amkt_http(uri).request(request)
    if (response.code == '200')
      response.body.force_encoding("UTF-8")
    else
      @log << [response.code, response.body]
      false
    end
  end

  def authentication store
    contact = Contact.new params[:vendor]
    if !amkt_authenticate(contact.email, contact.password) {|cookie| store[:amkt_cookie] = cookie}
      flash[:warning] = "Login incorrect"
    end
    contact
  end

  def do_import
    @log = Array.new
    flash[:vendor] = authentication(flash)
    flash[:log] = @log
    redirect_to import_licenses_path
  end

  def sales
    @vendor = session[:vendor]
  end

  def sales_update
    session[:vendor] = authentication(session)
    redirect_to sales_licenses_path
  end

  def sales_data
    respond_to do |format|
      format.json do
        uri = URI.parse('https://marketplace.atlassian.com/rest/1.0/vendors/120/sales' +
          "?limit=#{params[:limit]}&offset=#{params[:offset]}")
        request = Net::HTTP::Get.new(uri.request_uri, {'Cookie' => session[:amkt_cookie]})
        response = amkt_http(uri).request(request)
        if (response.code == '200')
          render :json => response.body
        else
          render :json => {:error => response.body}
        end
      end
    end
    
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