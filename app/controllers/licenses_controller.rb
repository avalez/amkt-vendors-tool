class LicensesController < ApplicationController
  def index
    @licenses = License.find :all
  end

  def pivot
    @licenses = License.find(:all).reduce({}) do |m, row|
      startDate = row['startDate']
      record = m[startDate] || {}
      edition = row['edition']
      record[edition] = 1 + (record[edition] || 0)
      m[startDate] = record
      m
    end
  end
end