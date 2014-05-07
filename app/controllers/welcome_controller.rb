require 'has_scope'

class WelcomeController < ApplicationController
  has_scope :location

  def index
    @devices = apply_scopes(Device).all

    @devices_by_location = {}
    @devices.each do |device|
      @devices_by_location[device.location] ||= []
      @devices_by_location[device.location] << device
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @devices }
    end
  end
end
