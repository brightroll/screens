class WelcomeController < ApplicationController
  def index
    @devices = Device.find(:all, :order => 'name')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @devices }
    end
  end
end
