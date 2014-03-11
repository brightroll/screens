#!/usr/bin/env ruby

require 'logger'
require 'optparse'
require 'socket'

$log = Logger.new(STDOUT)
$log.level = Logger::INFO

def loginTV(socket, username, password)
  $log.info "Login as #{username}"
  while line = socket.recv(100)
    case line
    when /^Login:/
      socket.send "#{username}\r", 0
    when /^Password:/
      socket.send "#{password}\r", 0
    else
      break
    end
  end
end

def sendTV(socket, command)
  $log.debug ("%-8s\r" % command)
  socket.send ("%-8s\r" % command), 0
  $log.debug socket.recv(100)
end

def doTV(tv, options={})
  $log.info "Talking to TV #{tv}"
  $0 = tv
  s = TCPSocket.new tv, 10002

  # The TV only sends a login prompt if a username/password is set
  # PEEK does not advance the read pointer, just checks if there's data
  # If there's nothing to read, recv_nonblock raises EWOULDBLOCK
  if (s.recv_nonblock(1, Socket::MSG_PEEK) rescue false)
    loginTV(s, options[:username], options[:password])
  end

  case options[:power]
  when :on
    sendTV(s, "POWR1")
    sleep 1 # Give the TV a second to power up
  when :off
    sendTV(s, "POWR0")
    s.close # TV is off, so we're done here
    return
  end

  case options[:volume]
  when :mute
    sendTV(s, "MUTE1")
  when Integer
    sendTV(s, "MUTE2")
    sendTV(s, "VOLM%02d" % options[:volume])
  end

  sendTV(s, "TVNM1")
  sendTV(s, "MNRD1")
  sendTV(s, "SWVN1")
  sendTV(s, "RSPW2")
  sendTV(s, "WIDE8")

  s.close
rescue Exception => e
  $log.warn "Failed to handle TV #{tv}: #{e}"
end

# Here begins

options = {
  :timeout => 30
}
opts = OptionParser.new do |opts|
  opts.banner = 'Sharp Aquos IP control on/off script'

  opts.on('--on', 'Turn TVs on') do |v|
    options[:power] = :on
  end
  opts.on('--off', 'Turn TVs off') do |v|
    options[:power] = :off
  end
  opts.on('--mute', 'Mute TVs') do |v|
    options[:volume] = :mute
  end
  opts.on('--volume NUM', Integer, 'Volume 0-99') do |v|
    options[:volume] = v.to_i
  end
  opts.on('--arp IF', String, 'Arp for TVs on this interface') do |v|
    options[:arp] = v
  end
  opts.on('--timeout NUM', 'Timeout to talk to TVs (default 30s)') do |v|
    options[:timeout] = v.to_i
  end
  opts.on('--username NUM', 'TV username') do |v|
    options[:username] = v
  end
  opts.on('--password NUM', 'TV password') do |v|
    options[:password] = v
  end
  opts.on('--verbose', 'Be verbose') do |v|
    $log.level = Logger::DEBUG
  end
  opts.on('--quiet', 'Be quiet') do |v|
    $log.level = Logger::WARN
  end
end

opts.parse!

if options[:arp]
  # This arp command line might be specific to Mac OS X
  tvs = %x(/usr/sbin/arp -na -i #{options[:arp]} | awk -F'[()]' '{print \$2}').split
elsif !ARGV.empty?
  tvs = ARGV
else
  $stderr.puts opts.help
  exit 1
end

tvs.each do |tv|
  fork do
    Timeout::timeout(options[:timeout]) do
      doTV tv, options
    end
  end
end

Process.waitall
