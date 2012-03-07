class Device < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A device with that name already exists"
  has_one :slideshow
end
