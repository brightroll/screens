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
  def browsed_device_link(airplay_device, hash_of_devices)
    device_name = airplay_device.name
    dev = hash_of_devices[device_name]
    if dev.nil?
      link_text = raw('<i class="icon-eye-open margin_right_8" title="Device seen on network"></i>') + h(device_name.to_s)
      link_to(link_text, new_device_path(:name => device_name))
    else
      link_text = raw('<i class="icon-ok-sign margin_right_8" title="Device seen on network is also in the database"></i>') + h(device_name.to_s)
      link_to(link_text, dev)
    end
  end
end
