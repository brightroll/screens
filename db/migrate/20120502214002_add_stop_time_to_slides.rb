class AddStopTimeToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :stop_time, :int
  end
end
