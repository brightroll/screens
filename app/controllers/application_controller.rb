class ApplicationController < ActionController::Base
  # Subclasses beware, your index and show methods are un-authenticated!
  before_filter :login_required, :except => [:index, :show]

  protect_from_forgery

  def login_required
    return true if current_user
    session[:return_to] = request.fullpath
    redirect_to '/auth/google_oauth2'
    return false
  end

  def current_user
    session[:user]
  end
  helper_method :current_user
end
