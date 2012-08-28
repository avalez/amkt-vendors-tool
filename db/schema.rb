# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120627210517) do

  create_table "add_ons", :force => true do |t|
    t.string "name"
    t.string "key"
  end

  create_table "addresses", :force => true do |t|
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.string "country"
  end

  create_table "contacts", :force => true do |t|
    t.string "email"
    t.string "name"
    t.string "phone"
  end

  create_table "licenses", :force => true do |t|
    t.string  "licenseId"
    t.string  "organisationName"
    t.integer "addOn_id"
    t.integer "technicalContact_id"
    t.integer "technicalContactAddress_id"
    t.integer "billingContact_id"
    t.string  "edition"
    t.string  "licenseType"
    t.string  "startDate"
    t.string  "endDate"
    t.string  "renewalAction"
  end

end
