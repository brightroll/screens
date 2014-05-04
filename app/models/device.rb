class Device < ActiveRecord::Base
  include ActiveModel::Validations
  include DevicesHelper
  extend FindBySlugHelper

  validates :name, :presence => true
  validates :deviceid, :uniqueness => true,
            :format => { :with => /([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}/,
                         :message => "MAC address must match format: 'AB:CD:EF:00:22:33'" }
  before_save :upcase_deviceid

  belongs_to :slideshow
  belongs_to :location

  attr_accessible :name, :location_id, :slideshow_id, :password, :deviceid

  default_scope -> { order(:name) }

  scope :location, -> loc do
    @location = Location.find_by_name(loc)
    @location ? where(location_id: @location.id).order(:name) : none
  end

  def thumbnail
    device_thumbnail(self)
  end

  def pid
    device_pid(self)
  end

  def slideshow_name
    slideshow.name if slideshow
  end

  def location_name
    location.name if location
  end

  def upcase_deviceid
    self.deviceid and self.deviceid.upcase!
    true
  end

  def to_param
    self.deviceid
  end
end
