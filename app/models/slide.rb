class Slide < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A slide with that name already exists"
  validates :url, :presence => true
  validates :display_time, :numericality => {
    :only_integer => true,
    :greater_than => 0, # At least 1 second
    :less_than => 1800 # And up to 30 minutes
  }, :unless => Proc.new { |a| [:audio, :video, :feed].include? a.media_type } # These types don't need a time
  validates :transition, :inclusion => { :in => Proc.new { Slide.transition_syms.values } }
  validates :media_type, :inclusion => { :in => Proc.new { Slide.media_type_syms.values } }

  has_many :slideshow_slides
  has_many :slideshows, :through => :slideshow_slides

  attr_accessible :name, :url, :transition, :display_time, :media_type, :feed_path, :scrub_time

  def media_type=(t)
    self[:media_type] = self.class.media_type_syms.fetch(t, :none)
  end

  def media_type
    self.class.media_type_syms.fetch(self[:media_type], :none)
  end

  def media_type_name
    self.class.media_type_names.fetch(media_type)
  end

  def self.media_type_syms
    {
      'image' => :image,
      'video' => :video,
      'audio' => :audio,
      'html' => :html,
      'none' => :none,
      # 'feed' => :feed,
    }
  end

  # TODO: use i18n for these
  def self.media_type_names
    {
      :image =>'Image',
      :video =>'Video',
      :audio =>'Audio',
      :html => 'Web URL',
      :none => 'None',
      # 'feed' => :feed,
    }
  end

  def transition=(t)
    self[:transition] = self.class.transition_syms.fetch(t, :none)
  end

  def transition
    self.class.transition_syms.fetch(self[:transition], :none)
  end

  def transition_name
    self.class.transition_names.fetch(transition)
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

  def feed_path=(t)
  end

  def feed_path
  end

  def scrub_time=(t)
  end

  def scrub_time
  end

end
