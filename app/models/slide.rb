class Slide < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A slide already exists with that name"
  validates :url, :presence => true
  has_many :slideshow_slides
  has_many :slideshows, :through => :slideshow_slides

  attr_accessible :name, :url, :transition, :display_time

  require 'mime/types'

  def transition=(t)
    self[:transition] = self.class.transition_syms.fetch(t, :none)
  end

  def transition
    self.class.transition_syms.fetch(self[:transition], :none)
  end

  def transition_name
    self.class.transition_names.fetch(transition)
  end

  # Infer media type from url
  def type
    begin
      # Prioritized order of media types
      types = MIME::Types.type_for(url).collect { |t| t.media_type }
      ['video', 'audio', 'image'].each { |t| return self.class.media_types.fetch(t) if types.include? t }
    rescue
    end
    :none
  end

  # Media types that are natively supported by AirPlay
  def self.media_types
    {
      'image' => :image,
      'video' => :video,
      'audio' => :audio,
    }
  end

  # See Airplay::Protocol::Image.transitions
  # Translate from valid string values to symbols
  def self.transition_syms
    {
      'none' => :none,
      'slide_left' => :slide_left,
      'slide_right' => :slide_right,
      'dissolve' => :dissolve,
    }
  end

  # TODO: use i18n for these
  def self.transition_names
    {
      :none         => "None",
      :slide_left   => "Slide Left",
      :slide_right  => "Slide Right",
      :dissolve     => "Dissolve"
    }
  end

end
