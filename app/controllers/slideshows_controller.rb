class SlideshowsController < ApplicationController
  # GET /slideshows
  # GET /slideshows.json
  def index
    @slideshows = Slideshow.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @slideshows }
    end
  end

  # GET /slideshows/1
  # GET /slideshows/1.json
  def show
    @slideshow = Slideshow.find(params[:id])
    @slides = @slideshow.slides

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @slideshow }
    end
  end

  # GET /slideshows/new
  # GET /slideshows/new.json
  def new
    @slideshow = Slideshow.new

    respond_to do |format|
      format.html # new.html.erb
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

  # POST /slideshows
  # POST /slideshows.json
  def create
    @slideshow = Slideshow.new(params[:slideshow])

    respond_to do |format|
      if @slideshow.save
        format.html { redirect_to @slideshow, notice: 'Slideshow was successfully created.' }
        format.json { render json: @slideshow, status: :created, location: @slideshow }
      else
        format.html { render action: "new" }
        format.json { render json: @slideshow.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /slideshows/1
  # PUT /slideshows/1.json
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

  # DELETE /slideshows/1
  # DELETE /slideshows/1.json
  def destroy
    @slideshow = Slideshow.find(params[:id])
    @slideshow.destroy

    respond_to do |format|
      format.html { redirect_to slideshows_url }
      format.json { head :no_content }
    end
  end
end
