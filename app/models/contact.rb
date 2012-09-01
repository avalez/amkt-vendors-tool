class Contact < ActiveRecord::Base
  #has_many :licenses, :as => :technicalContact
  attr_accessor :password
end