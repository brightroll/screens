#!/usr/bin/env ruby
$: << File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'vendor/bundle/bundler/setup.rb'

ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path('../../config/environment',  __FILE__)

require 'airplay'
require 'imgkit'

am_parent = 1
my_node = ""
node_pids = {}
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

def sleep_while_playing(player)
  for r in 1..5
    scrub = player.scrub
    if scrub and scrub.fetch('duration', 0) > 0
      puts "Got scrub on try #{r}"
      sleep scrub['duration']
      return
    end
    sleep 1
  end
end

# Take arg by name, rather than by object, to prevent instances crossing pids
def loop_slideshow(node_name)
  device = Device.find_by_name(node_name)
  unless device
    puts "Device #{node_name} is not in the database"
    return
  end

  slideshow = device.slideshow
  unless slideshow
    puts "Device #{node_name} has no slideshow"
    return
  end
  puts "Beginning slideshow #{slideshow.name} on device #{device.name} "

  airplay = Airplay::Client.new
  airplay.use node_name
  airplay.password device.password

  puts "Connected to device: #{airplay.inspect}"

  loop do
    slideshow.slides.each do |slide|
      # puts "Displaying slide #{slide.inspect}"
      case slide.type
      when :video
        puts "Sending video #{slide.url}"
        player = airplay.send_video(slide.url) # second arg is scrub position
        sleep_while_playing player
      when :audio
        puts "Sending audio #{slide.url}"
        player = airplay.send_audio(slide.url) # second arg is scrub position
        sleep_while_playing player
      when :image
        puts "Sending image #{slide.url}"
        airplay.send_image(slide.url, slide.transition)
        # sleep while the image is on the screen
        sleep slide.display_time
      else
        # Anything else gets rendered through WebKit
        puts "Rendering url #{slide.url}"
        airplay.send_image(IMGKit.new(slide.url).to_img, slide.transition, :raw => true)
        # sleep while the image is on the screen
        sleep slide.display_time
      end
    end

    # Reload the slideshow to pick up any changes
    slideshow = device.slideshow
  end

  puts "Ending slideshow for #{node_name}"
end

# Special function called by Kernel::at_exit
def at_exit
  if am_parent
    puts "Cleaning up children: #{node_pids.inspect}"
    node_pids.each do |node, pid|
      Process.kill("TERM", pid)
      Process.wait
    end
  else
    puts "Child exiting for device: #{my_node}."
  end
end

loop do
  # Every $loop_time seconds, look for airplay nodes.
  # If a node is found and there isn't a child process
  # for that node, spin one up!
  puts "Searching for AirPlay devices"

  airplay = Airplay::Client.new
  servers = begin
    airplay.browse
  rescue Airplay::Client::ServerNotFoundError
    []
  end

  servers.each do |node|
    # puts node.inspect
    unless node_pids.has_key? node.name
      node_pids[node.name] = Process.fork do
        am_parent = 0
        my_node = node.name
        loop_slideshow node.name
      end
    else
      puts "Slideshow already running on device #{node.name}"
    end
  end

  # Give the processes a moment to spin up and try connecting
  sleep 10

  node_pids.delete_if do |name, pid|
    begin
      wpid, status = Process.waitpid2(pid, Process::WNOHANG)

      if wpid
        puts "Reaping child for node #{name}: #{status.to_i} #{status.exitstatus}"
        true
      end
    rescue Errno::ESRCH # No such process
      true
    rescue Errno::ECHILD # Process already exited
      true
    rescue # Anything else
      puts "WARN: Possibly lost track of child pid #{pid}"
      true
    end
  end

  sleep LOOP_TIME
end
