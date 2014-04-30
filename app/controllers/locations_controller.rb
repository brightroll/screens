class LocationsController < ApplicationController
  inherit_resources
  respond_to :json

  def index
    index! do |format|
      format.html
      format.json
    end
  end
end
