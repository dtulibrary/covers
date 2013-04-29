require 'securerandom'

class UserController < ApplicationController
  http_basic_authenticate_with :name => (API_CONFIG['authentication'] ? API_CONFIG['authentication']['username'] : ''), :password => (API_CONFIG['authentication'] ? API_CONFIG['authentication']['password'] : '')
  before_filter :find_user, :only => [:show, :edit, :delete]
  
  attr_accessor :users, :user
  
  def index
    @users = User.find(:all)
  end
  
  def cache_reset
    Rails.cache.clear
    redirect_to user_path,:flash=>{:success => "The cache was cleared!"}
  end
  
  def show
    # @user = User.find(params[:id])#:first,:conditions=>{:api_key=>params[:id]})
  end
  
  def new
  end
  
  def edit
    # @user = User.find(params[:id])
  end
  
  def update
    # Validate params
    data = params[:user]
    data,invalid,invalid_param = validate_params(data)
    if invalid
      flash[:error] = "Invalid parameter: #{invalid_param}"
      redirect_to :action => :edit,:id=>params[:id]
    else
      @user = User.find(params[:id])#:first,:conditions=>{:api_key=>params[:id]}
      if @user.update_attributes(params[:user])
        redirect_to :action => :show, :id => @user.api_key
      else
        render 'edit'
      end
    end
  end
  
  def create
    # Validate params
    data = params[:user]
    data,invalid,invalid_param = validate_params(data)
    if invalid
      flash[:error] = "Invalid parameter: #{invalid_param}"
      render :new #:action => 
    else
      # Create user
      api_key = SecureRandom.urlsafe_base64(15)
      while User.find(:first,:conditions=>{:api_key=>api_key})#:first,:conditions=>{'api_key'=>api_key})
        api_key = SecureRandom.urlsafe_base64(15)
      end
      data['api_key'] = api_key
      @user = User.new(data)
      @user.save
      redirect_to :action => :show, :id => @user.api_key
    end
  end
  
  def delete
    # @user = User.find(params[:id])
    @user.destroy
    redirect_to :action => :index
  end
  
  protected
  def find_user
    @user = User.find(params[:id])
  end
  
  private
  def validate_params(data)
    codes = [200,404]
    invalid = false
    invalid_param = ''
    data[:on_missing_image] = data[:on_missing_image].to_i
    data[:on_missing_title] = data[:on_missing_title].to_i 
    if not data[:sn] =~ /\w+/
      invalid=true
      invalid_param = 'Short name'
    elsif not data[:ln] =~ /\w+/
      invalid=true
      invalid_param = 'Long name'
    elsif not data[:default_height] =~ /^\d+$/
      invalid=true
      invalid_param = 'Default height'
    elsif not data[:default_width] =~ /^\d+$/
      invalid=true
      invalid_param = 'Default width'
    elsif not codes.include? data[:on_missing_image]
      invalid=true
      invalid_param = 'On missing image'
    elsif not codes.include? data[:on_missing_title]
      invalid=true
      invalid_param = 'On missing title'
    end
    data[:default_height] = data[:default_height].to_i
    data[:default_width] = data[:default_width].to_i
    return data,invalid,invalid_param
  end
end
