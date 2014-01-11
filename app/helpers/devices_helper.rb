module DevicesHelper

  # Given a Device model object, returns a link to its slideshow if a slideshow exists, or
  # else returns an empty string.
  def device_slideshow_link(device)
    device.slideshow ? link_to(device.slideshow_name, device.slideshow) : ''
  end

  # Given an Airplay Device object and a hash {:name => <Device>}, it returns
  # link tag. If the Airplay Device name is pesent in the hash as a key, the associated
  # device model object is used to create the link. Otherwise a link with the URL
  # /devices/new?name=<name> is returned.
  #
  # Sample Output:
  #   <a href="/devices/1"><i class="icon-ok-sign" title="Device seen on network is also in the database"></i>Device1</a>
  #   <a href="/devices/new?name=IndikaAirplay"><i class="icon-eye-open" title="Device seen on network"></i>IndikaAirplay</a>
  def browsed_device_link(device, all_devices_by_deviceid)
    device_name = device.name
    dev = all_devices_by_deviceid[(device.info.mac_address rescue device.address)]
    if dev.nil?
      link_text = raw('<i class="icon-edit margin_right_8" title="Add this device"></i>') + h(device_name)
      link_to(link_text, new_device_path(:name => device_name, :deviceid => device.info.mac_address))
    else
      link_text = raw('<i class="icon-check margin_right_8" title="Device seen on network is also in the database"></i>') + h(device_name)
      link_to(link_text, dev)
    end
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
