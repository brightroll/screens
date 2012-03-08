class AddIndexOnDeviceName < ActiveRecord::Migration
  def change
    add_index :devices, :name
  end
end
