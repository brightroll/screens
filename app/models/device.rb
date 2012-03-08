class Device < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A device with that name already exists"
  belongs_to :slideshow
  
  def slideshow_name
    slideshow.name if slideshow
  end
end
