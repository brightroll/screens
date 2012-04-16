class LengthenSlideUrl < ActiveRecord::Migration
  def up
    change_column :slides, :url, :text
  end

  def down
    change_column :slides, :url, :string
  end
end
