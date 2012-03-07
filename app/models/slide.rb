class Slide < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A slide already exists with that name"
  validates :url, :presence => true
  belongs_to :slideshow
end
