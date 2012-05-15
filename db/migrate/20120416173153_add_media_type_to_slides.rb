class AddMediaTypeToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :media_type, :string, :limit => 16, :default => 'none', :null => false
  end
end
