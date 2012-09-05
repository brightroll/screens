class AddIndexOnDeviceDeviceId < ActiveRecord::Migration
  def change
    add_index :devices, :deviceid
  end
end
