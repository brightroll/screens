class SlideshowSerializer < ActiveModel::Serializer
  attributes :id, :name
  has_many :slides
end
