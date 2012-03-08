class SlideshowSlide < ActiveRecord::Base
  belongs_to :slideshow
  belongs_to :slide
end
