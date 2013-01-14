#!/usr/bin/env ruby

require 'socket'

def doTV(tv, power=nil, username='', password='')
  puts "Taking to TV #{tv}"
  s = TCPSocket.new tv, 10002

  while line = s.recv(100)
    case line
    when /^Login:/
      s.send "#{username}\r", 0
    when /^Password:/
      s.send "#{password}\r", 0
    else
      break
    end
  end

  case power
  when :on
    s.send "POWR1   \r", 0
    puts s.recv(100)
    sleep 1
  when :off
    s.send "POWR0   \r", 0
    puts s.recv(100)
    s.close
    return
  when :mute
    s.send "MUTE1   \r", 0
    puts s.recv(100)
  when Integer
    s.send "MUTE2   \r", 0
    puts s.recv(100)
    s.send "VOLM%02d  \r" % power, 0
    puts "VOLM%02d  \r" % power
    puts s.recv(100)
  end

  s.send "TVNM1   \r", 0
  puts s.recv(100)

  s.send "MNRD1   \r", 0
  puts s.recv(100)

  s.send "SWVN1   \r", 0
  puts s.recv(100)

  s.send "RSPW2   \r", 0
  puts s.recv(100)

  s.send "WIDE8   \r", 0
  puts s.recv(100)

  s.close
rescue Exception => e
  puts "Failed to handle TV #{tv}: #{e}"
end

# Here begins

case ARGV[0] 
when '--on'
  power = :on
  ARGV.shift
when '--off'
  power = :off
  ARGV.shift
when '--mute'
  power = :mute
  ARGV.shift
when '--volume'
  ARGV.shift
  power = ARGV.shift.to_i
end

ARGV.each do |tv|
  fork { doTV tv, power }
end

