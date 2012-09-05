#!/usr/bin/env ruby
$: << File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'vendor/bundle/bundler/setup.rb'

ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path('../../config/environment',  __FILE__)

require 'airplay'
require 'imgkit'
require 'image_science'
require 'digest/md5'

$am_parent = 1
$my_node = ""
$node_pids = {}
$pidfile = ""
LOOP_TIME = 50
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

def thumbnail(img, thumbname, thumbcopy = false)
  ImageScience::with_image_from_memory(img) do |science|
    science.thumbnail(640) do |thumb|
      thumb.save("public/thumbs/#{thumbname}.png")
      FileUtils.cp("public/thumbs/#{thumbname}.png",
                   "public/thumbs/#{thumbcopy}.png") if thumbcopy
      # Note the current thumbnail
      File.open("tmp/pids/device.#{$my_node.deviceid}.slide", File::CREAT|File::TRUNC|File::RDWR) { |f| f.write("public/thumbs/#{thumbname}.png") }
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

      y.yield ERB.new(<<EOF
<html>
  <head>
    <title><%= title %></title>
    <base href="<%= base_uri %>" />
  </head>
  <body bgcolor="black">
    <span style="color: white; font-size: 80px;"><%= title %> <%= page %>/<%= pages %></span>
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

# Take arg by name, rather than by object, to prevent instances crossing pids
def loop_slideshow(node)
  device = Device.find_by_name(node.name)
  unless device
    $log.debug("Device #{node} is not in the database")
    return
  end

  slideshow = device.slideshow
  unless slideshow
    $log.debug("Device #{node} has no slideshow")
    return
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
        player = airplay.send_video(slide.url) # second arg is scrub position
        # TODO: video thumbnail...
        sleep_while_playing player
        player.stop

      when :audio
        $log.info("Sending audio #{slide.url}")
        player = airplay.send_audio(slide.url) # second arg is scrub position
        # TODO: audio thumbnail...
        sleep_while_playing player
        player.stop

      when :image
        $log.info("Sending image #{slide.url}")
        airplay.send_image(slide.url, slide.transition.to_sym)
        # TODO: image url means the image is not local
        # sleep while the image is on the screen
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
        rescue Exception => e
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
        rescue Exception => e
          $log.error("Failed to render url (other error): #{slide.url} #{e}")
        end

      end
    end

    # Reload the device as it may have a new slideshow associated
    device.reload
    # Reload the slideshow to pick up slide changes
    slideshow = device.slideshow
  end

  $log.info("Ending slideshow for #{node}")
end

# Special function called by Kernel::at_exit
def at_exit
  reap
end

def on_hup
  reap
end

# When the parent gets a sigterm, kill itself
def on_term
  reap
  exit
end

def reap
  if $am_parent
    $log.info("Cleaning up children: #{$node_pids.inspect}")
    $node_pids.each do |node, pid|
      Process.kill("KILL", pid)
    end
    Process.waitall
  else
    $log.info("Child exiting for device: #{$my_node.name} #{$my_name.deviceid}.")
    File.delete($pidfile) if $pidfile
  end
end

loop do
  # Every $loop_time seconds, look for airplay nodes.
  # If a node is found and there isn't a child process
  # for that node, spin one up!

  Signal.trap("HUP", proc { on_hup })
  Signal.trap("TERM", proc { on_term })

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
        $am_parent = 0
        $my_node = node
        $pidfile = "tmp/pids/airserver.#{node.deviceid}.pid"
        File.open($pidfile, File::CREAT|File::TRUNC|File::RDWR) { |f| f.write Process.pid }
        $log = Logger.new("log/airserver.#{node.deviceid}.log")
        $log.level = Logger::INFO
        $0 = "#{$0} #{$my_node.name} #{$my_node.deviceid}"
        loop_slideshow $my_node
      end
    else
      $log.debug("Slideshow already running on device #{node.name}")
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
    rescue # Anything else
      $log.warn("Possibly lost track of child pid #{pid}")
      true
    end
  end

  sleep LOOP_TIME
end
