class ApplicationController < ActionController::Base
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
