#!/usr/bin/env ruby
$: << File.expand_path(File.join(File.dirname(__FILE__), '..'))
require 'vendor/bundle/bundler/setup.rb'

ENV['RAILS_ENV'] ||= 'development'
require File.expand_path('../../config/environment',  __FILE__)

require 'airplay'
require 'imgkit'
require 'image_science'
require 'digest/md5'
require 'socket'
require 'mime/types'

$am_parent = true
$my_node = ''
$node_pids = {}
$pidfile = nil
$slidefile = nil
LOOP_TIME = 30
STANDARD_DISPLAY_TIME = 5

$log = Logger.new('log/airserver.log')
$log.level = Logger::INFO

IMGKit.configure do |config|
  config.wkhtmltoimage = [
        '~/bin/wkhtmltoimage',          # Personal ~/bin
        '/usr/local/bin/wkhtmltoimage', # Homebrew
        '/opt/local/bin/wkhtmltoimage', # Macports
        '/usr/bin/wkhtmltoimage',       # Installed
       ].select { |f| File.exist? f }.first
  config.default_options = {
    :format => :png,
    :height => 1080,
    :width => 1920,
    :quality => 10,
    :javascript_delay => 5000,
  }
end

def sleep_while_playing(player)
  for r in 1..5
    scrub = player.scrub
    if scrub and scrub.fetch('duration', 0) > 0
      $log.debug("Got scrub on try #{r}")
      sleep scrub['duration']
      return
    end
    sleep 1
  end
end

def video_thumbnail(file, thumbname, thumbcopy = false)
  cmd = ["ffmpeg", "-loglevel", "quiet", "-i", file, "-vframes", "1", "-s", "640x360", "public/thumbs/#{thumbname}.png"]
  $log.debug(cmd.join(' '))
  if system(*cmd)
    FileUtils.cp("public/thumbs/#{thumbname}.png",
                 "public/thumbs/#{thumbcopy}.png") if thumbcopy
    # Note the current thumbnail
    File.open($slidefile, File::CREAT|File::TRUNC|File::RDWR) { |f| f.write("thumbs/#{thumbname}.png") }
  end
rescue StandardError => e
  $log.error("Failed to generate thumbnail for #{file} at #{thumbname}: #{e}")
end

def thumbnail(img, thumbname, thumbcopy = false)
  ImageScience::with_image_from_memory(img) do |science|
    science.thumbnail(640) do |thumb|
      thumb.save("public/thumbs/#{thumbname}.png")
      FileUtils.cp("public/thumbs/#{thumbname}.png",
                   "public/thumbs/#{thumbcopy}.png") if thumbcopy
      # Note the current thumbnail
      File.open($slidefile, File::CREAT|File::TRUNC|File::RDWR) { |f| f.write("thumbs/#{thumbname}.png") }
    end
  end
end

# Returns HTML suitable for rendering a Graphite dashboard
def graphite_dashboard_fetch(graphite_uri)
  uri = URI(graphite_uri)
  req = Net::HTTP::Get.new(uri.request_uri)
  resp = Net::HTTP.start(uri.hostname, uri.port){ |http| http.request(req) }

  graphite = resp.body

  base_uri = 'http://' + uri.hostname
  title = JsonPath.new('$.state.name').on(graphite)[0]
  graphs = JsonPath.new('$.state.graphs[:][2]').on(graphite)

  return base_uri, title, graphs
end

def graphite_dashboard_html(base_uri, title, graphs)
  pages = graphs.length / 4 + (graphs.length % 4 == 0 ? 0 : 1)
  page = 0

  Enumerator.new do |y|
    while page < pages do
      ga = graphs[page * 4 + 0]
      gb = graphs[page * 4 + 1]
      gc = graphs[page * 4 + 2]
      gd = graphs[page * 4 + 3]
      page += 1

      time_fmt = Time.now.strftime("Rendered at %F %T %Z")

      y.yield ERB.new(<<EOF
<html>
  <head>
    <title><%= title %></title>
    <base href="<%= base_uri %>" />
  </head>
  <body bgcolor="black">
    <div style="width: 960px; height: 80px; position: absolute; left: 0px; top: 0px;">
      <span style="color: white; font-size: 76px; line-height: 80px; vertical-align: bottom;"><%= title %> <%= page %>/<%= pages %></span>
    </div>
    <div style="width: 960px; height: 80px; position: absolute; left: 960px; top: 0px;">
      <span style="color: white; font-size: 48px; line-height: 80px; vertical-align: bottom;"><%= time_fmt %></span>
    </div>
    <% if ga %><img style="width: 960px; height: 500px; position: absolute; left: 0px; top: 80px;" src="<%= ga %>" /><% end %>
    <% if gb %><img style="width: 960px; height: 500px; position: absolute; left: 960px; top: 80px;" src="<%= gb %>" /><% end %>
    <% if gc %><img style="width: 960px; height: 500px; position: absolute; left: 0px; top: 580px;" src="<%= gc %>" /><% end %>
    <% if gd %><img style="width: 960px; height: 500px; position: absolute; left: 960px; top: 580px;" src="<%= gd %>" /><% end %>
  </body>
</html>
EOF
      ).result binding
    end
  end
end

def file_name_url(url)
  if url && !url.starts_with?('http://', 'https://')
    url = 'http://' + Socket.gethostname + url
  end
  url
end

# Take arg by name, rather than by object, to prevent instances crossing pids
def loop_slideshow(node)
  device = Device.find_by_deviceid(node.deviceid)
  unless device
    $log.debug("Device #{node.name} #{node.deviceid} is not in the database")
    raise NoDeviceError
  end

  slideshow = device.slideshow
  unless slideshow
    $log.debug("Device #{node.name} #{node.deviceid} has no slideshow")
    raise NoSlideshowError
  end
  $log.info("Beginning slideshow #{slideshow.name} on device #{device.name}")

  airplay = Airplay::Client.new node
  airplay.password device.password
  $log.debug("Connected to device: #{airplay.inspect}")

  loop do
    slideshow.slides.each do |slide|
      $log.debug("Displaying slide #{slide.inspect}")

      case ( slide.media_type and slide.media_type.to_sym or nil )
      when :video
        $log.info("Sending video #{slide.url}")
        url = file_name_url(slide.url)
        player = airplay.send_video(url) # second arg is scrub position
        # TODO: video thumbnail...
        sleep_while_playing player
        player.stop

      when :feed
        # For now, a feed is a directory path to videos
        Dir.glob(File.join('public', slide.url, '**')).each do |movie|
          $log.info("Sending video file #{movie}")
          next unless MIME::Types.type_for(movie).find(/video/)
          url = file_name_url(movie.gsub(/public/, ''))
          player = airplay.send_video(url) # second arg is scrub position
          video_thumbnail(movie, Digest::MD5.hexdigest(slide.url))
          sleep_while_playing player
          player.stop
        end

      when :audio
        $log.info("Sending audio #{slide.url}")
        url = file_name_url(slide.url)
        player = airplay.send_audio(url) # second arg is scrub position
        # TODO: audio thumbnail...
        sleep_while_playing player
        player.stop

      when :image
        $log.info("Sending image #{slide.url}")
        url = file_name_url(slide.url)
        airplay.send_image(url, slide.transition.to_sym)
        begin
          img = Net::HTTP.get_response(URI(url)).body
          thumbnail(img, Digest::MD5.hexdigest(url))
        rescue StandardError => e
          $log.error("Failed to thumbnail image url: #{url} #{e}")
        end
        sleep slide.display_time

      when :graphite
        begin
          $log.info("Rendering Graphite #{slide.url}")
          base_url, title, graphs = graphite_dashboard_fetch(slide.url)
          graphite_dashboard_html(base_url, title, graphs).each do |dashboard|
            img = IMGKit.new(dashboard).to_img
            airplay.send_image(img, slide.transition.to_sym, :raw => true)
            thumbnail(img, Digest::MD5.hexdigest(slide.url))
            # sleep one slide time length for each portion of the dashboard
            sleep slide.display_time
          end
        rescue IMGKit::CommandFailedError
          $log.error("Failed to render graphite with IMGKit: #{slide.url}")
        rescue StandardError => e
          $log.error("Failed to render graphite (other error): #{slide.url} #{e}")
        end

      else
        begin
          # Anything else gets rendered through WebKit
          $log.info("Rendering url #{slide.url}")
          img = IMGKit.new(slide.url).to_img
          airplay.send_image(img, slide.transition.to_sym, :raw => true)
          thumbnail(img, Digest::MD5.hexdigest(slide.url))
          # sleep while the image is on the screen
          sleep slide.display_time
        rescue IMGKit::CommandFailedError
          $log.error("Failed to render url with IMGKit: #{slide.url}")
        rescue StandardError => e
          $log.error("Failed to render url (other error): #{slide.url} #{e}")
        end

      end
    end

    # Reload the device as it may have a new slideshow associated
    device.reload
    # Reload the slideshow to pick up slide changes
    slideshow = device.slideshow
  end

  $log.info("Ending slideshow for #{node.name} #{node.deviceid}")
end

def reap(sig)
  $log.info("Cleaning up children: #{$node_pids.inspect}")
  $node_pids.each do |node, pid|
    Process.kill(sig, pid)
  end
  Process.waitall
end

class Hangup < SignalException; end
class NoDeviceError < StandardError; end
class NoSlideshowError < StandardError; end

def child_main(node)
  $am_parent = false
  $node_pids = {}
  $my_node = node
  $pidfile = "tmp/pids/airserver.#{node.deviceid}.pid"
  $slidefile = "tmp/pids/device.#{node.deviceid}.slide"
  File.open($pidfile, File::CREAT|File::TRUNC|File::RDWR) { |f| f.write Process.pid }
  $log = Logger.new("log/airserver.#{node.deviceid}.log")
  $log.level = Logger::INFO
  $0 = "#{$0} #{$my_node.name} #{$my_node.deviceid}"
  loop do
    begin
      loop_slideshow $my_node
    rescue Hangup
      $log.info("Restarting slideshow immediately.")
    end
  end
  $log.info("Child exiting for device: #{$my_node.name} #{$my_name.deviceid}.")
end

# Install signal handlers

at_exit do
  begin
    reap(:SIGKILL) if $am_parent
    File.delete($pidfile) if $pidfile
    File.delete($slidefile) if $slidefile
  rescue # Doesn't matter, we're exiting
  end
end

trap :SIGHUP do
  reap(:SIGHUP) if $am_parent
  raise Hangup unless $am_parent
end

# Parent main from here on

loop do
  # Every $loop_time seconds, look for airplay nodes.
  # If a node is found and there isn't a child process
  # for that node, spin one up!

  airplay = begin
    $log.info("Searching for AirPlay devices")
    Airplay::Client.new
  rescue Airplay::Client::ServerNotFoundError
    $log.info("No devices found, sleeping #{LOOP_TIME} seconds")
    sleep LOOP_TIME
    next
  end

  airplay.servers.each do |node|
    $log.debug(node.inspect)
    unless $node_pids.has_key? node.deviceid
      $node_pids[node.deviceid] = Process.fork do
        child_main node
      end
      $log.info("Started airserver for device #{node.name} #{node.deviceid} with pid #{$node_pids[node.deviceid]}")
    else
      $log.debug("Slideshow already running on device #{node.name} #{node.deviceid}")
    end
  end

  # Give the processes a moment to spin up and try connecting
  sleep 10

  $node_pids.delete_if do |name, pid|
    begin
      wpid, status = Process.waitpid2(pid, Process::WNOHANG)

      if wpid
        $log.debug("Reaping child for node #{name}: #{status.to_i} #{status.exitstatus}")
        true
      end
    rescue Errno::ESRCH # No such process
      true
    rescue Errno::ECHILD # Process already exited
      true
    rescue StandardError => e # Anything else
      $log.warn("Possibly lost track of child pid #{pid}: #{e}")
      true
    end
  end

  sleep LOOP_TIME
end
