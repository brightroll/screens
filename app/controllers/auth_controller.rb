class AuthController < ApplicationController
  def login
    # user will immediately be redirected to google to log in.
    # args are 1) your domain, 2) your "finish" controller action, and
    # 3) any required ax params (email/firstname/lastname/language)
    google_apps_authenticate ::Rails.application.config.googleapps_auth_domain, 'finish', [:email]
  end

  def finish
    response = google_apps_handle_auth
    if response.failed? or response.canceled?
      flash[:notice] = "Could not authenticate: #{response.error}"
    else
      # start a session, log user in.  AX values are arrays, get first.
      session[:user] = response[:email].first
      flash[:notice] = "Thanks for logging in, #{response[:email].first}"
    end
    redirect_to :root
  end

# Default is in-memory store. Uncomment this method to use another OpenID store.
#  protected
#  def store
#    OpenID::Store::Memcache.new(MemCache.new('localhost:11211'))
#    # or OpenID::Store::Filesystem.new(Rails.root.join('tmp/openids'))
#  end
end
