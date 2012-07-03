class LicensesController < ApplicationController
  def licenses
    @licenses = License.find session[:editions] ? session[:editions].keys : :all
  end

  def restful
    if (params[:editions] != session[:editions])
      redirect_to :action => action_name, :editions => session[:editions]
    end
    session[:editions] = params[:editions] || session[:editions]
  end

  def index
    restful
    licenses
    @all_editions = License.all_editions
  end

  def filter
    session[:editions] = params[:editions]
    redirect_to send params[:return_to], :editions => session[:editions]
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

  def chart
    respond_to do |format|
      format.html do
        restful
        @all_editions = License.all_editions
      end
      format.json do
        pivot_licenses
        json = { :all_editions => @all_editions,
          :pivot => @pivot}
        render :json => json
      end
    end
  end

  def geo_licenses
    licenses
    @geo = @licenses.reduce({}) do |m, row|
      country = row['technicalContactCountry']
      m[country] = 1 + (m[country] || 0)
      m
    end
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