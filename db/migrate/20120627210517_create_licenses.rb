class CreateLicenses < ActiveRecord::Migration
  def up
    create_table :licenses do |t|
      t.string :license_id
      t.string :organisation_name
      t.references :add_on
      t.column :technical_contact_id, :integer, :references => :contact
      t.column :technical_contact_address_id, :integer, :references => :address
      t.column :billing_contact_id, :integer, :references => :contact
      t.string :edition
      t.string :license_type
      t.string :start_date
      t.string :end_date
      t.string :renewal_action
    end

    # it's impossible to set string primary key, see
    # http://stackoverflow.com/questions/1200568/using-rails-how-can-i-set-my-primary-key-to-not-be-an-integer-typed-column
    # but it also is not possible to add primary key in sqlite3 alter table statement, see
    # http://stackoverflow.com/questions/1249290/sql-adding-composite-primary-key-through-alter-table-option
    create_table :add_ons do |t|
      t.string :name
      t.string :key
      t.references :contact
    end

    create_table :contacts do |t|
      t.string :email
      t.string :name
      t.string :phone
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
