class LicensesController < ApplicationController
  def defaults
    @fromDate = Date.new(2012,04,28)
    @toDate = Date.new(2012,12,28)
    if (session[:fromDate] && session[:toDate])
      @fromDate = date session[:fromDate]
      @toDate = date session[:toDate]
    end
    @all_editions = License.all_editions
  end
  def licenses
    defaults
    filter = {}
    if (session[:editions])
      filter['edition'] = session[:editions].keys
    end
    if (session[:countries])
      filter['technicalContactCountry'] = session[:countries].keys
    end
    if (session[:fromDate] && session[:toDate])
      filter[:startDate] = @fromDate .. @toDate
    end
    @licenses = License.where filter
  end

  def date param
    Date.civil(param[:year].to_i, param[:month].to_i, param[:day].to_i)
  end

  def restful
    if (params[:editions] != session[:editions] ||
        params[:countries] != session[:countries] ||
        params[:fromDate] != session[:fromDate] ||
        params[:toDate] != session[:toDate])
      redirect_to :action => action_name,
        :editions => session[:editions], :countries => session[:countries],
        :fromDate => session[:fromDate], :toDate => session[:toDate]
      return false
    else
      session[:editions] = params[:editions] || session[:editions]
      session[:countries] = params[:countries] || session[:countries]
      session[:fromDate] = params[:fromDate] || session[:fromDate]
      session[:toDate] = params[:toDate] || session[:toDate]
      return true
    end
  end

  def filter
    session[:editions] = params[:editions]
    session[:countries] = params[:countries]
    session[:fromDate] = params[:fromDate]
    session[:toDate] = params[:toDate]
    redirect_to send params[:return_to],
      :editions => session[:editions], :countries => session[:countries],
      :fromDate => session[:fromDate], :toDate => session[:toDate]
  end
  
  def index
    restful or return false
    licenses
    geo
    @sum = @licenses.reduce(0) {|sum, license| sum + (license['price'] || 0)}
    @all_countries = @geo.keys
    #@licenses = @licenses.select("*, count(*) as count").includes([:technicalContact]).
    #  group("licenseId", "organisationName",
    #  "technicalContact_id", "technicalContactAddress_id", "edition", "licenseType", "startDate", "endDate")
    @licenses = @licenses.sort_by {|license| license['organisationName']}
  end

  def bought
    index or return
    @licenses = @licenses.find_all {|license| License.paid_licenseTypes.include? license['licenseType']}
    @licenses = @licenses.sort_by {|license| license['startDate']}
    render :action => 'index'
  end

  def notbought
    index or return
    @licenses = @licenses.sort_by {|license| license['organisationName']}
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
    @licenses = @licenses.find_all {|license| license['endDate'] <= '2012-07-31' && license['endDate'] >= '2012-06-30'}
    @licenses = @licenses.sort_by {|license| license['organisationName']} 
    @sum = 0
    render :action => 'index'
  end

  def pivot_licenses
    licenses
    @total = Hash[@all_editions.map {|edition, price| [edition, 0]}]
    @pivot = @licenses.reduce({}) do |m, row|
      startDate = row['startDate']
      record = m[startDate] || {}
      edition = row['edition']
      record[edition] = 1 + (record[edition] || 0)
      m[startDate] = record
      @total[edition] += 1
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
      country = row['technicalContactCountry'] || 'N/A'
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
    @log = License.import
  end
end