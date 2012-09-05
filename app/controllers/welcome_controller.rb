class WelcomeController < ApplicationController
  def index
    @devices = Device.find(:all, :order => 'name')

    @now_playing = {}
    @devices.each do |d|
      begin
        @now_playing[d.deviceid] = File.open("tmp/pids/device.#{d.deviceid}.slide") { |f| f.read }
      rescue
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @devices }
    end
  end
end
