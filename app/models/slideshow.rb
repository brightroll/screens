class Slideshow < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A slideshow already exists with that name"
  has_many :slideshow_slides
  has_many :slides, :through => :slideshow_slides
  
  accepts_nested_attributes_for :slides, :slideshow_slides
end
