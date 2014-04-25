class Location < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A location already exists with that name"
  has_many :devices
  attr_accessible :name
end
