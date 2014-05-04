class LocationsController < ApplicationController
  inherit_resources
  respond_to :json

  def index
    index! do |format|
      format.html
      format.json
    end
  end

  protected
  def collection
    get_collection_ivar || set_collection_ivar(end_of_association_chain.paginate(:page => params[:page]))
  end
end
