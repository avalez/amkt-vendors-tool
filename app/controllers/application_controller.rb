require 'password'

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate
  
  protected

  def authenticate
    Rails.env != 'production' || authenticate_or_request_with_http_basic do |username, password|
      username == ENV['amkt_client_username'] && Password.check(password, ENV['amkt_client_password'])
    end
  end
end
