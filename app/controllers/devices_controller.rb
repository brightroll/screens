require 'has_scope'

class DevicesController < ApplicationController
  inherit_resources
  respond_to :json

  has_scope :location

  def index
    index! do |format|
      format.html
      format.json
    end
  end

  def power
    case params['state']
    when 'on'
      %x{bin/aquos.rb --quiet --arp en3 --on}
    when 'off'
      %x{bin/aquos.rb --quiet --arp en3 --off}
    end
    redirect_to url_for(:devices)
  end

  def browse
    @devices = begin
      Airplay.devices
    rescue Airplay::Client::ServerNotFoundError => e
      []
    rescue StandardError => e
      flash.now[:error] = "An error occurred while retrieving the list of Airplay devices on the network: " + e.to_s
      []
    end
    @all_devices_by_deviceid = Hash[Device.all.map { |d| [d.deviceid, d] }]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @devices }
    end
  end

  # Signal a running process (default TERM)
  def signal
    @device = Device.find(params[:id])
    signal = params.fetch(:signal, 'TERM')
    pid = @device.pid

    if signal && pid
      begin
        Process.kill(signal, pid)
        @signalled = { :signal => signal, :pid => pid }
      rescue StandardError => e
        @signalled = { :error => "Exception: #{e}" }
      end
    else
      @signalled = { :error => 'Invalid arguments' }
    end

    render json: @signalled
  end

  protected
  def resource
    get_resource_ivar || set_resource_ivar(end_of_association_chain.find_by_slug!(params[:id]))
  end

  def collection
    get_collection_ivar || set_collection_ivar(end_of_association_chain.paginate(:page => params[:page]))
  end
end
