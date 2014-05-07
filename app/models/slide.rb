class Slide < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A slide with that name already exists"
  validates :url, :presence => true
  validates :display_time, :numericality => {
    :only_integer => true,
    :greater_than => 0, # At least 1 second
    :less_than => 1800 # And up to 30 minutes
  }, :unless => Proc.new { |a| [:audio, :video, :feed].include? a.media_type.to_sym } # These types don't need a time

  extend Enumerize
  enumerize :transition, :in => [:none, :slide_left, :slide_right, :dissolve], :default => :dissolve
  enumerize :media_type, :in => [:html, :image, :video, :audio, :graphite, :feed], :default => :html

  has_many :slideshow_slides
  has_many :slideshows, :through => :slideshow_slides

  attr_accessible :name, :url, :transition, :display_time, :media_type, :feed_path, :scrub_time, :stop_time

  default_scope -> { order(:name) }
end
