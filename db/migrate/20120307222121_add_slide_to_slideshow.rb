class AddSlideToSlideshow < ActiveRecord::Migration
  def change
    create_table :slideshow_slides do |t|
      t.references :slideshow, :null => false
      t.references :slide, :null => false
    end
    
    add_column :devices, :slideshow_id, :integer, :key => true
  end
end
