#!/usr/bin/env ruby
$: << File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'vendor/bundle/bundler/setup.rb'

ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path('../../config/environment',  __FILE__)

require 'airplay'
require 'imgkit'

node_threads = {}
LOOP_TIME = 50
STANDARD_DISPLAY_TIME = 5

IMGKit.configure do |config|
  config.default_options = {
    :format => :png,
    :height => 1080,
    :width => 1920,
    :quality => 10
  }
end

# Take arg by name, rather than by object, to prevent instances crossing threads
def begin_slideshow(node_name)
  puts "Looking for #{node_name} in the slideshow database..."
  device = Device.find_by_name(node_name)
  return unless device

  puts "Connecting to device: #{device.inspect}"

  slideshow = device.slideshow
  puts "Beginning slideshow #{slideshow.name} #{slideshow.inspect}"

  airplay = Airplay::Client.new
  airplay.use node_name
  airplay.password device.password

  puts "Connected to device: #{airplay.inspect}"

  while slide = slideshow.next_slide!
    case slide.type
    when :image
      airplay.send_image(slide.url, slide.transition)
    when :video
      airplay.send_video(slide.url) # second arg is scrub position
    when :audio
      airplay.send_audio(slide.url) # second arg is scrub position
    when :html
      airplay.send_image(IMGKit.new(slide.url).to_img, slide.transition, :raw => true)
    end

    sleep slide.display_time
  end

  puts "Ending slideshow for #{node_name}"
end

loop do
  # Every $loop_time seconds, look for airplay nodes.
  # If a node is found and there isn't a thread
  # for that node, spin one up!
  puts "Searching for AirPlay devices"

  airplay = Airplay::Client.new
  airplay.browse.each do |node|
    puts node.inspect
    unless node_threads.has_key? node.name
      node_threads[node.name] = Thread.new { begin_slideshow node.name }
    end
  end

  # Give the threads a moment to spin up and try connecting
  node_threads.each do |name, thr|
    thr.run
  end

  Thread.pass
  sleep 10

  node_threads.delete_if do |name, thr|
    unless thr.alive?
      puts "Reaping thread for node #{name}"
      thr.join(0.50) # shouldn't block, but just in case, timeout.
      true
    end
  end

  sleep LOOP_TIME
end
