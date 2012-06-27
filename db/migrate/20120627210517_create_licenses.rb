class CreateLicenses < ActiveRecord::Migration
  def up
    create_table :licenses do |t|
      t.string :license_id
      t.string :organization_name
      t.string :edition
      t.string :license_type
      t.string :start_date
      # Add fields that let Rails automatically keep track
      # of when records are added or modified:
      t.timestamps
    end
  end

  def down
    drop_table :licenses
  end
end
