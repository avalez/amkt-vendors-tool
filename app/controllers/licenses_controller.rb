class LicensesController < ApplicationController
  def index
    session[:editions] = params[:editions] || session[:editions]
    @licenses = License.find session[:editions] ? session[:editions].keys : :all
    @all_editions = License.all_editions
  end

  def filter
    session[:editions] = params[:editions]
    redirect_to params[:return_url], :editions => session[:editions]
  end

  def pivot
    index
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

  def chart
    @all_editions = License.all_editions
    respond_to do |format|
      format.html
      format.json do
        pivot
        json = { :all_editions => @all_editions,
          :pivot => @pivot}
        render :json => json
      end
    end
  end
end