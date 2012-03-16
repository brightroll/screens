class SlideshowSlide < ActiveRecord::Base
  belongs_to :slideshow
  belongs_to :slide

  attr_accessible :slide_id, :slideshow_id
end
