class ApplicationController < ActionController::Base
  protect_from_forgery
  
  # Rescue from
  rescue_from ActionController::RoutingError, :with => :render_http_error
  rescue_from ArgumentError, :with => :render_http_error
  rescue_from RSolr::Error::Http, :with => :render_internal_server_error
  rescue_from Errno::ECONNREFUSED, :with => :render_internal_server_error
  
  # Authenticate users if certain criteria are met.
  # - No authentication will be done if user is already logged in.
  # - No authentication will be done if an authentication provider 
  #   has not been chosen. This will also check for sticky choice
  #   from :auth_provider cookie.
  def authenticate
    # Use sticky auth provider if it isn't already set in session
    session[:auth_provider] ||= cookies[:auth_provider]

    # No authentication if user is already logged in
    unless session[:user_id]
      # Only do authentication if an auth provider has been chosen
      session[:auth_provider] = 'dtu_cas'
      if session[:auth_provider]
        # Return URL could be set by the authentication provider selection page
        session[:return_url] ||= request.url
        # Recreate user abilities on each login
        @current_ability = nil
        redirect_to polymorphic_url(:new_user_session)
      end
    end
  end
  
  def current_user
    user = logged_in_user || guest_user
    user.walk_in = walk_in_request?
    return user
  end

  def logged_in_user
    if session[:user_id]
      user = User.find session[:user_id]
      user.impersonating = session.has_key? :original_user_id if user
      return user
    end
  end
  
  # Call this to bail out quickly and easily when something is not found.
  # It will be rescued and rendered as a 404
  
  # Raise 404
  def not_found
    raise ActionController::RoutingError.new 'Not found'
  end
  
  # Raise 401
  def unauthorized
    raise ActionController::RoutingError.new 'Unauthorized'
  end
  
  # Raise 400
  def bad_request
    raise ArgumentError.new 'Bad request'
  end
  
  # Raise 415
  def unsupported_media_type
    raise ArgumentError.new 'Unsupported media type'
  end
  
  # Raise 501
  def not_implemented
    raise ArgumentError.new 'Not implemented'
  end
  
  def render_error(code=nil)
    if code == 400
      bad_request
    elsif code == 404
      not_found
    else
      not_found # Render 404 in case of unknown error code.
    end
  end
  
  def render_http_error(exception)
    case exception.message
    when 'Not found'
      render :file => 'public/404', :format => :html, :status => :not_found, :layout => false
    when 'Unauthorized'
      render :file => 'public/401', :format => :html, :status => :unauthorized, :layout => false
    when 'Bad request'
      render :file => 'public/400', :format => :html, :status => :bad_request, :layout => false
    when 'Unsupported media type'
      render :file => 'public/415', :format => :html, :status => :unsupported_media_type, :layout => false
    when 'Not implemented'
      render :file => 'public/501', :format => :html, :status => :not_implemented, :layout => false
    else # Default error choice is 404 Not Found.
      render :file => 'public/404', :format => :html, :status => :not_found, :layout => false
    end
  end
  
  # Render 500
  def render_internal_server_error
    render :file => 'public/500', :format => :html, :status => :internal_server_error, :layout => false
  end

end
