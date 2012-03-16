class AuthController < ApplicationController
  skip_before_filter :login_required

  def login
    google_apps_auth_begin :attrs => [:firstname, :lastname, :email]
  end

  def logout
    reset_session
    redirect_to :back
  end

  def finish
    response = google_apps_auth_finish
    if response.failed? or response.canceled?
      flash[:notice] = "Could not authenticate: #{response.error}"
    else
      # start a session, log user in.  AX values are arrays, get first.
      session[:user] = response[:email].first
      flash[:notice] = "Thanks for logging in, #{response[:email].first}"
    end
    redirect_to :back
  end

# Default is in-memory store. Uncomment this method to use another OpenID store.
#  protected
#  def store
#    OpenID::Store::Memcache.new(MemCache.new('localhost:11211'))
#    # or OpenID::Store::Filesystem.new(Rails.root.join('tmp/openids'))
#  end
end
