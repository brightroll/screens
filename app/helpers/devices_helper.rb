module DevicesHelper
  # Given a Device object, returns a link to its location if a location exists
  # or else returns an empty string.
  def device_location_link(device)
    device.location ? link_to(device.location_name, device.location) : ''
  end

  # Given a Device object, returns a link to its slideshow if a slideshow exists
  # or else returns an empty string.
  def device_slideshow_link(device)
    device.slideshow ? link_to(device.slideshow_name, device.slideshow) : ''
  end

  # Get the pid of the currently-running airserver for this device
  def device_pid(device)
    begin
      pid = File.open("tmp/pids/airserver.#{device.deviceid}.pid").read.to_i
      Process.kill 0, pid
      pid
    rescue
    end
  end

  # Get the thumbnail that airserver generates for each slide change
  def device_thumbnail(device)
    File.open("tmp/pids/device.#{device.deviceid}.slide").read rescue nil
  end
end
