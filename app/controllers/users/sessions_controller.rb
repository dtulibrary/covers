class Users::SessionsController < ApplicationController
  skip_before_filter :authenticate, :only => [ :create, :new ]

  def new
    session[:return_url] ||= '/'
    redirect_to omniauth_path(:dtu_cas)
  end

  def create
    # extract authentication data
    auth = request.env["omniauth.auth"]
    logger.debug auth.extra.hashie_inspect
    username = auth.extra.user

    unless Rails.application.config.authorized_users.include?(username)
      unauthorized
    end

    session[:user_id] = username
    redirect_to session.delete(:return_url), :notice => 'You are now logged in', :only_path => true
  end

  def omniauth_path(provider)
    "/auth/#{provider.to_s}"
  end

end
