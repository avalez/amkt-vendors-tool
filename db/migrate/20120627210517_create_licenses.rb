class CreateLicenses < ActiveRecord::Migration
  def up
    create_table :licenses, :id => false do |t|
      t.string :license_id
      t.column :organisation_name, :string, :references => :organisation
      t.references :add_on
      t.column :technical_contact, :integer, :references => :contact
      t.column :technical_contact_address, :integer, :references => :address
      t.column :billing_contact, :integer, :references => :contact
      t.string :edition
      t.string :license_type
      t.string :start_date
    end

    create_table :organisations, :id => false do |t|
      t.string :organisation_name, :options => 'PRIMARY KEY'
    end

    create_table :add_ons, :id => false do |t|
      t.string :add_on_name
      t.string :add_on_key, :options => 'PRIMARY KEY'
    end

    create_table :contacts do |t|
      t.string :email
      t.string :name
    end

    create_table :addresses do |t|
      t.string :address_1
      t.string :address_2
      t.string :city
      t.string :state
      t.string :post_code
      t.string :country
    end
  end

  def down
    drop_table :licenses
    drop_table :organisations
    drop_table :add_ons
    drop_table :contacts
    drop_table :addresses
  end
end
