class Device < ActiveRecord::Base
  include ActiveModel::Validations
  validates :name, :presence => true
  validates :deviceid, :uniqueness => true
  belongs_to :slideshow

  attr_accessible :name, :slideshow_id, :password, :deviceid

  before_save :upcase_deviceid

  def slideshow_name
    slideshow.name if slideshow
  end

  def upcase_deviceid
    self.deviceid and self.deviceid.upcase!
    true
  end
end
