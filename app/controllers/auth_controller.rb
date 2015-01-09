require 'omniauth/google_oauth2'

class AuthController < ApplicationController
  skip_before_filter :login_required

  def logout
    reset_session
    redirect_to :back
  end

  def finish
    email = request.env['omniauth.auth'].to_hash['info']['email'].to_s.downcase
    if valid_email?(email)
      session[:user] = email
      flash[:notice] = "Thanks for logging in, #{email.split('@').first.capitalize}."
      redirect_to (session[:return_to] || '/')
    else
      session.delete(:user)
      flash[:notice] = "Could not authenticate: #{response.error}"
      redirect_to (session[:return_to] || '/')
    end
  end

  protected
  def valid_email?(email)
    domain = email.split('@').last
    valid_email_domains.empty? || (domain && valid_email_domains.include?(domain))
  end

  def valid_email_domains
    @valid_email_domains ||= (ENV['SCREENS_VALID_EMAIL_DOMAINS'] || '').split(',').map(&:downcase)
  end
end
