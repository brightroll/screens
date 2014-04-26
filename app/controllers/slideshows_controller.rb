class SlideshowsController < ApplicationController
  inherit_resources

  def show
    @slideshow = Slideshow.find(params[:id])
    @slides = @slideshow.slides

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @slideshow }
    end
  end

  # GET /slideshows/1/edit
  def edit
    @slideshow = Slideshow.find(params[:id])
    @slides = @slideshow.slides
    @slide = Slide.new

    respond_to do |format|
      format.html # edit.html.erb
      # javascript-encoded partial to go into a hover window
      format.js { render :inline => "$('<%= params[:update] %>').html('<%= escape_javascript(render :partial => 'slideshows/form' ) %>')" }
    end
  end

  def update
    @slideshow = Slideshow.find(params[:id])

    @slideshow.slides += params[:add_slides].map{ |es| Slide.find(es) } if params[:add_slides]

    @slideshow.slideshow_slides.where(:slide_id => params[:del_slides]).delete_all

    respond_to do |format|
      if @slideshow.update_attributes(params[:slideshow])
        format.js { render :nothing => true }
        format.html { redirect_to (params[:existing_slides] ? edit_slideshow_path(@slideshow) : @slideshow), notice: 'Slideshow was successfully updated.' }
        format.json { head :no_content }
      else
        format.js { render :nothing => true }
        format.html { render action: "edit" }
        format.json { render json: @slideshow.errors, status: :unprocessable_entity }
      end
    end
  end
end
