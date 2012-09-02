class WelcomeController < ApplicationController
  def index
    @devices = Device.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @devices }
    end
  end
end
