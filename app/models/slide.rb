class Slide < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A slide already exists with that name"
  validates :url, :presence => true
  has_many :slideshow_slides
  has_many :slideshows, :through => :slideshow_slides

# FIXME
#  def transition
#    self.transitions.fetch(transition) || :none
#  end

  # Translate from valid string values to symbols
  def self.transitions
    {
      'none' => :none,
      'slide_left' => :slide_left,
      'slide_right' => :slide_right,
      'dissolve' => :dissolve,
    }
  end
end
