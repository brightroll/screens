class Device < ActiveRecord::Base
  validates :name, :presence => true
  validates_uniqueness_of :name, :message => "A device with that name already exists"
  belongs_to :slideshow

  def slideshow_name
    slideshow.name if slideshow
  end

  # Returns a hash of the form {<Device Name> => <Device obj>} for all Devices
  # in the database.
  def self.saved_device_hash
    all.inject({}) do |h, dev|
      h[dev.name] = dev
      h
    end
  end

end
