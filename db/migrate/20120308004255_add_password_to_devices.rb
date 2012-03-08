class AddPasswordToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :password, :string
  end
end
