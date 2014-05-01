#!/usr/bin/env ruby

require 'airplay'
require 'imgkit'
require 'image_science'
require 'digest/md5'
require 'socket'
require 'mime/types'
require 'uri'
require 'net/http'
require 'net/https'
require 'jsonpath'
require 'docopt'
require 'active_resource'

DOCOPT = <<END
Screens Server

Run this on the remote headend for each display location.
Use the --device option to drive a single airplay target in the foreground.
Use the --location option to drive an entire site; one child will fork per airplay target.

Usage:
  #{__FILE__} --location=<location> [--server=<server>] [--loop=<time>] [--logfile=<file>] [--verbose]
  #{__FILE__} --device=<deviceid>   [--server=<server>]                 [--logfile=<file>] [--verbose]

Options:
  --server=<server>  Screen server url [default: http://#{Socket.gethostname}/]
  --loop=<time>      Airplay device discovery loop time in seconds [default: 30]
  --logfile=<file>   Log file (can be 'STDOUT') [default: log/airserver.log]
  --verbose          Verbose logging
  -h --help          Show this help text
  --version          Show the version
END

begin
  $opts = Docopt::docopt(DOCOPT)
rescue Docopt::Exit => e
  puts e.message
  exit 1
end

puts $opts.inspect

class Device < ActiveResource::Base
  self.site = $opts['--server']
  self.include_format_in_path = false
end

class Slideshow < ActiveResource::Base
  self.site = $opts['--server']
  self.include_format_in_path = false
end

class Slide < ActiveResource::Base
  self.site = $opts['--server']
  self.include_format_in_path = false
end

$am_parent = true
$my_node = ''
$node_pids = {}
$pidfile = nil
$slidefile = nil

$opts['--logfile'] = STDOUT if $opts['--logfile'] == 'STDOUT'
$log = Logger.new($opts['--logfile'])
$log.level = $opts['--verbose'] ? Logger::DEBUG : Logger::INFO

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
  if url && !url.start_with?('http://', 'https://')
    url = $opts['--server'] + url
  end
  url
end

def loop_slideshow(device)
  airplay = Airplay[device.name]
  fail unless airplay
  airplay.password = device.password
  $log.debug("Connected to device: #{airplay.inspect}")

  loop do
    # Reload on every loop in case the slideshow or slides have changed
    slideshow = Slideshow.find(device.reload.slideshow_id)
    unless slideshow
      $log.debug("Device #{device.name} #{device.deviceid} has no slideshow")
      raise NoSlideshowError
    end
    $log.info("Beginning slideshow #{slideshow.name} on device #{device.name}")

    # Prevent slamming the server if there is no slideshow for this device
    sleep 5 if slideshow.slides.empty?

    slideshow.slides.each do |slide|
      $log.info("Displaying slide #{slide.inspect}")
      $log.debug("Displaying slide #{slide.inspect}")

      case ( slide.media_type and slide.media_type.to_sym or nil )
      when :video
        url = file_name_url(slide.url)
        $log.info("Sending video #{url}")
        player = airplay.play(url) # second arg is scrub position
        video_thumbnail(slide.url, Digest::MD5.hexdigest(slide.url))
        player.wait
        player.stop

      when :feed
        # For now, a feed is a directory path to videos
        # TODO: Use airplay gem 1.0 playlists!
        Dir.glob(File.join('public', slide.url, '**')).each do |movie|
          next unless MIME::Types.type_for(movie).find(/video/)
          url = file_name_url(movie.gsub(/public/, ''))
          $log.info("Sending video file #{url}")
          player = airplay.send_video(url) # second arg is scrub position
          video_thumbnail(movie, Digest::MD5.hexdigest(slide.url))
          player.wait
          player.stop
        end

      when :audio
        $log.info("Sending audio #{slide.url}")
        url = file_name_url(slide.url)
        player = airplay.send_audio(url) # second arg is scrub position
        # TODO: audio thumbnail...
        player.wait
        player.stop

      when :image
        url = file_name_url(slide.url)
        $log.info("Sending image #{url}")
        airplay.view(url, :transition => slide.transition.to_s)
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
            airplay.view(img, :transition => slide.transition.to_s)
            thumbnail(img, Digest::MD5.hexdigest(slide.url))
            # sleep one slide time length for each portion of the dashboard
            sleep slide.display_time
          end
        rescue IMGKit::CommandFailedError => e
          $log.error("Failed to render graphite with IMGKit: #{slide.url} #{e}")
        rescue StandardError => e
          $log.error("Failed to render graphite (other error): #{slide.url} #{e}")
        end

      else
        begin
          # Anything else gets rendered through WebKit
          $log.info("Rendering url #{slide.url}")
          img = IMGKit.new(slide.url).to_img
          airplay.view(img, :transition => slide.transition.to_s)
          thumbnail(img, Digest::MD5.hexdigest(slide.url))
          # sleep while the image is on the screen
          sleep slide.display_time
        rescue IMGKit::CommandFailedError => e
          $log.error("Failed to render url with IMGKit: #{slide.url} #{e}")
        rescue StandardError => e
          $log.error("Failed to render url (other error): #{slide.url} #{e}")
        end

      end
    end
  end

  $log.info("Ending slideshow for #{device.name} #{device.deviceid}")
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

if $opts['--device']
  # Just run a child straight away
  name = $opts['--device']
  node = Device.find(name)
  abort "Cannot find device for #{name}" unless node
  puts "Direct connection to #{node.name}"
  exit child_main node
end

loop do
  # Every $loop_time seconds, query the database for devices
  # If a node is found and there isn't a child process for that node, spin one up!

  devices = Device.find(:all, :params => { :location => $opts['--location'] })
  devices.each do |node|
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

  sleep $opts['--loop']
end
