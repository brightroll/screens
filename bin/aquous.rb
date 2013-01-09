#!/usr/bin/env ruby

require 'socket'

def doTV(tv, power=nil, username='', password='')
  puts "Taking to TV #{tv}"
  s = TCPSocket.new tv, 10002

  while line = s.recv(100)
    case line
    when /^Login:/
      s.sendmsg "#{username}\r"
    when /^Password:/
      s.sendmsg "#{password}\r"
    else
      break
    end
  end

  case power
  when :on
    s.sendmsg "POWR1   \r"
    puts s.recv(100)
    sleep 1
  when :off
    s.sendmsg "POWR0   \r"
    puts s.recv(100)
    s.close
    return
  when :mute
    s.sendmsg "MUTE1   \r"
    puts s.recv(100)
  when Integer
    s.sendmsg "MUTE2   \r"
    puts s.recv(100)
    s.sendmsg "VOLM%02d  \r" % power
    puts "VOLM%02d  \r" % power
    puts s.recv(100)
  end

  s.sendmsg "TVNM1   \r"
  puts s.recv(100)

  s.sendmsg "MNRD1   \r"
  puts s.recv(100)

  s.sendmsg "SWVN1   \r"
  puts s.recv(100)

  s.sendmsg "RSPW2   \r"
  puts s.recv(100)

  s.sendmsg "WIDE8   \r"
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

