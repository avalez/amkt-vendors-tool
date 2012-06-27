class LicensesController < ApplicationController
  def index
    @licenses = License.find :all
  end
end