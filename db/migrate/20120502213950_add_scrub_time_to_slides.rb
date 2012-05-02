class AddScrubTimeToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :scrub_time, :int
  end
end
