#require 'dtubase'

class Users::SessionsController < ApplicationController
  skip_before_filter :authenticate, :only => [ :create, :new ]

  def new
    session[:return_url] ||= '/'
    if session[:auth_provider]
      redirect_to omniauth_path(session[:auth_provider].to_sym)
    else 
      redirect_to select_auth_provider_path
    end
  end

  def create
    # extract authentication data
    auth = request.env["omniauth.auth"]
    logger.debug auth.extra.hashie_inspect
    provider = params['provider']
    username = auth.extra.user
    
    
    unauthorized if not Rails.application.config.authorized_users.include?(username)

    session[:user_id] = username

    # Make CanCan re-initialize abilities based on new user id
    @current_ability = nil

    # redirect user to the requested url
    redirect_to session.delete(:return_url), :notice => 'You are now logged in', :only_path => true
  end
  
  def omniauth_path(provider)
    "/auth/#{provider.to_s}"
  end
  
end
