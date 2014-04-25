class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string   :name,       :null => false
      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
    end

    add_index :locations, :name, :unique => true

    add_column :devices, :location_id, :integer
  end
end
