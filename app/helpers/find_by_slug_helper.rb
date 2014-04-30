module FindBySlugHelper
  def find_by_slug!(id)
    puts self.inspect
    case id
    when Integer, /^\d+$/
      find_by_id!(id)
    else
      find_by_deviceid!(id)
    end
  end
end
