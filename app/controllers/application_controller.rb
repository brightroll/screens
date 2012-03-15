class ApplicationController < ActionController::Base
  # Subclasses beware, your index and show methods are un-authenticated!
  before_filter :login_required, :except => [:index, :show]

  protect_from_forgery

  def login_required
    if session[:user]
      return true
    end
    flash[:warning] = 'Login required.'
    session[:return_to] = request.fullpath
    redirect_to :controller => "auth", :action => "login"
    return false
  end

  def current_user
    session[:user]
  end
end
