class AddDeviceIdToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :deviceid, :string, :limit => 20
  end
end
