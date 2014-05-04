require 'has_scope'

class WelcomeController < ApplicationController
  has_scope :location

  def index
    @devices = apply_scopes(Device).all
    @locations = Location.joins(:devices).all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @devices }
    end
  end
end
