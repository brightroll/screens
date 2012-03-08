#!/usr/bin/env ruby
$: << File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'vendor/bundle/bundler/setup.rb'

require 'airplay'
require 'imgkit'

node_threads = {}
loop_time = 50
STANDARD_DISPLAY_TIME = 5

IMGKit.configure do |config|
  config.default_options = {
    :format => :png,
    :height => 1080,
    :width => 1920,
    :quality => 10
  }
end

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

  def self.find(name)
    new :name => name
  end
end

# Take arg by name, rather than by object, to prevent instances crossing threads
def begin_slideshow(node_name)
  puts "Looking for #{node_name} in the slideshow database..."
  slideshow = MockSlideshow.find(node_name)
  puts "Beginning slideshow #{slideshow.name} #{slideshow.inspect}"

  airplay = Airplay::Client.new
  airplay.use node_name

  puts airplay.inspect

  while slide = slideshow.next_slide!
    case slide.type
    when :image
      airplay.send_image(slide.url, slide.transition)
    when :video
      airplay.send_video(slide.url) # second arg is scrub position
    when :audio
      airplay.send_audio(slide.url) # second arg is scrub position
    when :html
      airplay.send_image(IMGKit.new(slide.url).to_img, slide.transition, true)
    end

    sleep slide.display_time
  end

  puts "Ending slideshow for #{node_name}"
end

loop do
  # Every $loop_time seconds, look for airplay nodes.
  # If a node is found and there isn't a thread
  # for that node, spin one up!

  airplay = Airplay::Client.new
  airplay.browse.each do |node|
    puts node.inspect
    unless node_threads.has_key? node.name
      node_threads[node.name] = Thread.new { begin_slideshow node.name }
    end
  end

  # Give the threads a moment to spin up and try connecting
  sleep 10

  node_threads.delete_if do |name, thr|
    unless thr.alive?
      puts "Reaping thread for node #{name}"
      thr.join(0.50) # shouldn't block, but just in case, timeout.
      true
    end
  end

  sleep loop_time
end
