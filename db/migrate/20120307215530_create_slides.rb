class CreateSlides < ActiveRecord::Migration
  def change
    create_table :slides do |t|
      t.string :name
      t.string :url
      t.integer :display_time
      t.string :transition

      t.timestamps
    end
  end
end
