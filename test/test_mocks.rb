
class MockSlide
  attr_reader :id, :type, :url, :transition, :display_time

  def initialize(args)
    @type = args[:type]
    @url = args[:url]
    @transition = args[:transition]
    @display_time = args[:display_time]
  end
end

class MockSlideshow
  attr_reader :id, :pos, :name, :slides

  def initialize(args)
    @name = args[:name]
    @pos = -1
    @slides = [
      MockSlide.new(:type => :html, :display_time => STANDARD_DISPLAY_TIME, :transition => :dissolve, :url => "http://www.brightroll.com"),
      MockSlide.new(:type => :html, :display_time => STANDARD_DISPLAY_TIME, :transition => :dissolve, :url => "http://www.cnn.com"),
      MockSlide.new(:type => :image, :display_time => STANDARD_DISPLAY_TIME, :transition => :dissolve, :url => "Monitor.png"),
      MockSlide.new(:type => :image, :display_time => STANDARD_DISPLAY_TIME, :transition => :dissolve, :url => "Coffee.jpg"),
    ]
  end

  def next_slide!
    @slides[@pos += 1]
  end

  def next_slide
    @slides[@pos + 1]
  end

  def self.find_by_name(name)
    new :name => name
  end
end

