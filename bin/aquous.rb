#!/usr/bin/env ruby

require 'logger'
require 'optparse'
require 'socket'

$log = Logger.new(STDOUT)
$log.level = Logger::INFO

def doTV(tv, options={})
  $log.info "Talking to TV #{tv}"
  s = TCPSocket.new tv, 10002

  while line = s.recv(100)
    case line
    when /^Login:/
      s.send "#{options[:username]}\r", 0
    when /^Password:/
      s.send "#{options[:password]}\r", 0
    else
      break
    end
  end

  case options[:power]
  when :on
    s.send "POWR1   \r", 0
    $log.debug s.recv(100)
    sleep 1
  when :off
    s.send "POWR0   \r", 0
    $log.debug s.recv(100)
    s.close
    return
  end

  case options[:volume]
  when :mute
    s.send "MUTE1   \r", 0
    $log.debug s.recv(100)
  when Integer
    s.send "MUTE2   \r", 0
    $log.debug s.recv(100)
    s.send "VOLM%02d  \r" % options[:volume], 0
    $log.debug s.recv(100)
  end

  s.send "TVNM1   \r", 0
  $log.debug s.recv(100)

  s.send "MNRD1   \r", 0
  $log.debug s.recv(100)

  s.send "SWVN1   \r", 0
  $log.debug s.recv(100)

  s.send "RSPW2   \r", 0
  $log.debug s.recv(100)

  s.send "WIDE8   \r", 0
  $log.debug s.recv(100)

  s.close
rescue Exception => e
  $log.warn "Failed to handle TV #{tv}: #{e}"
end

# Here begins

options = {}
OptionParser.new do |opts|
  opts.banner = 'Sharp Aquous IP control on/off script'

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
    options[:volume] = v
  end
  opts.on('--arp IF', String, 'Arp for TVs on this interface') do |v|
    options[:arp] = v
  end
  opts.on('--verbose', 'Be verbose') do |v|
    $log.level = Logger::DEBUG
  end
  opts.on('--quiet', 'Be quiet') do |v|
    $log.level = Logger::WARN
  end
end.parse!

options[:username] = ''
options[:password] = ''

if options[:arp]
  tvs = %x(/usr/sbin/arp -na -i #{options[:arp]} | awk -F'[()]' '{print \$2}').split
elsif !ARGV.empty?
  tvs = ARGV
else
  $log.warn "Usage: #{$0} [--on | --off] [--mute | --volume 0-99] <--arp IF | TV IPs>"
  exit 1
end

tvs.each do |tv|
  fork { doTV tv, options }
end

Process.waitall
