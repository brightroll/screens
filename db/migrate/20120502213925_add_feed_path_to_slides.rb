class AddFeedPathToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :feed_path, :text
  end
end
