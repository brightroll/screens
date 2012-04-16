class ShortenSlideTransition < ActiveRecord::Migration
  def up
    change_column :slides, :transition, :string, :limit => 16, :default => 'none', :null => false
  end

  def down
    change_column :slides, :transition, :string
  end
end
