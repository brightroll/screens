module DevicesHelper
  
  def device_slideshow_link(device)
    device.slideshow ? link_to(device.slideshow_name, device.slideshow) : ''
  end
end
