#!/usr/bin/ruby
$: << File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'vendor/bundle/bundler/setup.rb'

require 'airplay'

airplay = Airplay::Client.new
airplay.browse
