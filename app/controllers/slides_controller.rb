class SlidesController < ApplicationController
  inherit_resources
  respond_to :json

  def index
    index! do |format|
      format.html
      format.json
    end
  end

  def create
    @slide = Slide.new(params[:slide])

    # If we're creating a new slide from the slideshow editing page, add the
    # slide to the slideshow and then redirect to the slideshow edit screen.
    @slide.slideshows << (@slideshow = Slideshow.find(params[:slideshow_id])) if params[:slideshow_id]

    respond_to do |format|
      if @slide.save
        format.html { redirect_to (@slideshow ? edit_slideshow_path(@slideshow) : @slide), notice: 'Slide was successfully created.' }
        format.json { render json: @slide, status: :created, location: @slide }
      else
        format.html { render action: "new" }
        format.json { render json: @slide.errors, status: :unprocessable_entity }
      end
    end
  end
end
