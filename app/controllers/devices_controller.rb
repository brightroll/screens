class DevicesController < ApplicationController
  # GET /devices
  # GET /devices.json
  def index
    @devices = Device.find(:all, :order => 'name')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @devices }
    end
  end

  # GET /devices/1
  # GET /devices/1.json
  def show
    @device = Device.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @device }
    end
  end

  def browse
    @devices = begin
      Airplay::Client.new.browse
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

  # GET /devices/new
  # GET /devices/new.json
  def new
    @device = Device.new :name => params[:name], :deviceid => params[:deviceid]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @device }
    end
  end

  # GET /devices/1/edit
  def edit
    @device = Device.find(params[:id])
  end

  # POST /devices
  # POST /devices.json
  def create
    @device = Device.new params[:device]

    respond_to do |format|
      if @device.save
        format.html { redirect_to @device, notice: 'Device was successfully created.' }
        format.json { render json: @device, status: :created, location: @device }
      else
        format.html { render action: "new" }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /devices/1
  # PUT /devices/1.json
  def update
    @device = Device.find(params[:id])

    respond_to do |format|
      if @device.update_attributes(params[:device])
        format.html { redirect_to @device, notice: 'Device was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /devices/1
  # DELETE /devices/1.json
  def destroy
    @device = Device.find(params[:id])
    @device.destroy

    respond_to do |format|
      format.html { redirect_to devices_url }
      format.json { head :no_content }
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
end
