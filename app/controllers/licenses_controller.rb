class LicensesController < ApplicationController
  def licenses
    filter = {}
    if (session[:editions])
      filter['edition'] = session[:editions].keys
    end
    if (session[:countries])
      filter['technicalContactCountry'] = session[:countries].keys
    end
    @licenses = License.find filter
  end

  def restful
    if (params[:editions] != session[:editions] ||
        params[:countries] != session[:countries])
      redirect_to :action => action_name, :editions => session[:editions], :countries => session[:countries]
    else
      session[:editions] = params[:editions] || session[:editions]
      session[:countries] = params[:countries] || session[:countries]
    end
  end

  def index
    restful
    licenses
    geo
    @all_countries = @geo.keys
    @all_editions = License.all_editions
  end

  def notbought
    index
    @licenses = @licenses.sort_by {|license| license['organisationName']}
    @licenses_map = @licenses.reduce({}) do |m, license|
      organisationName = license['organisationName'] || 'N/A'
      licenses = m[organisationName] || []
      licenses <<= license
      m[organisationName] = licenses
      m
    end
    @licenses_map = @licenses_map.select do |organisationName, licenses|
      licenses.index {|license| license['edition'] != 'Evaluation'} == nil
    end
    @licenses = @licenses_map.values.flatten 1
    render :action => 'index'
  end

  def filter
    session[:editions] = params[:editions]
    session[:countries] = params[:countries]
    redirect_to send params[:return_to], :editions => session[:editions], :counties => session[:editions]
  end
  
  def pivot_licenses
    licenses
    @all_editions = License.all_editions
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
        @all_editions = License.all_editions
      end
      format.json do
        geo_licenses
        json = { :geo => @geo}
        render :json => json
      end
    end
  end
end