class LicensesController < ApplicationController
  def index
    @licenses = License.find :all
  end

  def pivot
    @all_editions = License.all_editions
    @total = Hash[@all_editions.map {|edition, price| [edition, 0]}]
    @licenses = License.find(:all).reduce({}) do |m, row|
      startDate = row['startDate']
      record = m[startDate] || {}
      edition = row['edition']
      record[edition] = 1 + (record[edition] || 0)
      m[startDate] = record
      @total[edition] += 1
      m
    end
  end
end