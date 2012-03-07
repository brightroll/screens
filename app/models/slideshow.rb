class Slideshow < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A slideshow already exists with that name"
  has_many :slides
end
