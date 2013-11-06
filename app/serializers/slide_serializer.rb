class SlideSerializer < ActiveModel::Serializer
  attributes :id, :name, :media_type, :url, :thumbnail, :display_time,  :scrub_time, :stop_time, :transition

  def thumbnail
    hash = Digest::MD5.hexdigest(object.url)
    "/thumbs/#{hash}.png"
  end
end
