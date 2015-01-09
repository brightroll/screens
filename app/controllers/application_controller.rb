class ApplicationController < ActionController::Base
  # Subclasses beware, your index and show methods are un-authenticated!
  before_filter :login_required, :except => [:index, :show]

  protect_from_forgery

  def login_required
    return true if current_user
    session[:return_to] = request.fullpath
    redirect_to login_path
    return false
  end

  def current_user
    session[:user]
  end
  helper_method :current_user

  def login_path
    '/auth/google_oauth2'
  end
  helper_method :login_path
end
