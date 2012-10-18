#require 'net/http'
#require 'uri'
#require 'rsolr'
require 'RMagick'
require 'rmagick_text_util.rb'
require 'date'

class ApiController < ApplicationController
  # Includes
  include RMagickTextUtil
  include ApiHelper
  # Params
  attr_accessor :api_key,:id,:region,:size,:rotation,:file
  # Repository path variables
  attr_accessor :service_location
  # Other variables
  attr_accessor :transformed_image,:cache_id,:mime_type,:file_extension,:user,:request_ip
  # Log variables
  attr_accessor :start_time,:total_time,:cache_hit,:image_hit,:title_hit,:response_time_image
  attr_accessor :response_time_title,:image_proc_time,:image_synth_time
  # Info variables
  attr_accessor :info_width,:info_height,:formats,:qualities
  # Regular expression patterns (only the ones which are used in more than one location have been made into constants)
  ID_PATTERN = /\S/ # Should not test on semantics of the ID but rather just treat it as an ID and test whether it has an image for it or not /^(\d{8}|\d{7}x|x\d{7})$|^(\d{13}|\d{12}x|x\d{12})$/i
  ISSN_PATTERN = /^(\d{8}|\d{7}x|x\d{7})$/i
  
  def info
    ### Get request ip ###
    @request_ip = request.remote_ip
    ### Set compliance level header ###
    response.headers["X-Link"]=API_CONFIG['iiif_compliance']['header']
    ### Set incoming parameters as class variables ###
    @api_key = params[:api_key]
    @id = params[:id]
    @formats = ["jpg", "png"]
    @qualities = ["native"]
    is_bad_request = false
    @user = User.find(:first,:conditions=>{:api_key=>@api_key})#:first, :conditions=>{:api_key => @api_key})
    render_401 and return if not @user
    is_bad_request = true if not @id =~ ID_PATTERN
    if is_bad_request
      render_400(false) and return
    end
    ### Set repository path variables ###
    @service_location = (@id =~ ISSN_PATTERN ? API_CONFIG['imagerepository']['service_location_journal'] : API_CONFIG['imagerepository']['service_location_book'])
    ### Fetch Image ###
    was_found,image_data = fetch_image
    @image_hit = was_found
    if was_found
      ### Transform Image ###
      timer = Time.now.to_f
      # Load image
      @transformed_image = Magick::Image::from_blob(image_data).first
      @info_width = @transformed_image.columns
      @info_height = @transformed_image.rows
    else
      render_404(false) and return
    end

    respond_to do |format|
      format.json
      format.xml
    end
  end
  
  def wiki
    ### Get request ip ###
    @request_ip = request.remote_ip
    ### Set compliance level header ###
    response.headers["X-Link"]=API_CONFIG['iiif_compliance']['header']
  end
  
  def index
    ### Get request ip ###
    @request_ip = request.remote_ip
    ### Set compliance level header ###
    response.headers["X-Link"]=API_CONFIG['iiif_compliance']['header']
    ### Set incoming parameters as class variables ###
    @api_key = params[:api_key]
    @id = params[:id]
    @region = params[:region]
    @size = params[:size]
    @rotation = params[:rotation]
    @start_time = Time.now.to_f #TODO: maybe this should be placed after verification ?
    render_400 and return if not params['format']
    render_415 and return if not params['format'] =~ /^(png|jpg)$/i
    render_501 and return if params[:file] =~ /^(color|gray|bitonal)$/i
    @file = (params[:file]+'.'+params['format']).downcase
    ### Verify parameters ###
    is_bad_request = false
    @user = User.find(:first,:conditions=>{:api_key=>@api_key})
    render_401 and return if not @user 
    if @user
      @region = (@region ? @region : "full") 
      @size = (@size ? @size : "#{@user.default_width},#{@user.default_height}")
      @rotation = (@rotation ? @rotation : "0")
    end
    
    render_501 and return if @rotation =~ /^\d+\.\d+$/
    @id.gsub!(/-/,"")
    is_bad_request = true if not @id =~ ID_PATTERN
    is_bad_request = true if not @region =~ /^full$|^\d+,\d+,\d+,\d+$|^pct:\d+,\d+,\d+,\d+$/
    is_bad_request = true if not @size =~ /^full$|^\d+,$|^,\d+$|^pct:\d+$|^\d+,\d+$|^!\d+,\d+$/
    is_bad_request = true if not @rotation =~ /^\d+$/
    is_bad_request = true if not @file =~ /^native\.(png|jpg)$/
    ### Set repository path variables ###
    @service_location = (@id =~ ISSN_PATTERN ? API_CONFIG['imagerepository']['service_location_journal'] : API_CONFIG['imagerepository']['service_location_book'])
    ### Initialize other variables ###
    @file_extension = @file.split('.')[1]
    @mime_type = "image/#{@file_extension}"
    @mime_type = "image/jpeg" if @file_extension == 'jpg'
    @file_extension = @file_extension.downcase
    ### Fetch Header or Handle error ###
    if is_bad_request
      render_400 and return
    else
      @cache_id = @id.to_s+"||"+@region.to_s+"||"+@size.to_s+"||"+@rotation.to_s+"||"+@file.to_s
      #Rails.cache.clear
      #cache_item = false
      cache_item = Rails.cache.read @cache_id
      if cache_item
        @cache_hit = true
        @image_hit = (cache_item['is_faked'] ? false : true)
        # Send transformed image as response
        Rails.cache.write @cache_id, cache_item, :expires_in => (ImageDeliveryService::Application.config.cache_duration).minute
        render_error(@user.on_missing_image) and return if cache_item['is_faked'] == true and not @user.on_missing_image == 200
        render_error(@user.on_missing_title) and return if cache_item['missing_title'] == true and not @user.on_missing_title == 200
        # Perform logging.
        write_to_log
        send_data(cache_item['blob'] , :filename => cache_item['filename'], :type=>cache_item['type']) and return
      else
        @cache_hit = false
      end
    end
    ### Fetch Image ###
    was_found,image_data = fetch_image
    @image_hit = was_found
    if was_found
      ### Transform Image ###
      timer = Time.now.to_f
      # Load image
      @transformed_image = Magick::Image::from_blob(image_data).first
      
      # Crop image
      render_400 and return if not crop_image
      
      # Scale image
      scale_image
      
      # Rotate image
      rotate_image
      
      # Convert image to correct format
      image_blob = convert_image_to_blob
      
      @image_proc_time = Time.now.to_f - timer #TODO: should this come before or after writing to cache ?
      
      # Cache image (if not already cached)
      Rails.cache.fetch @cache_id,:expires_in => (ImageDeliveryService::Application.config.cache_duration).minute do
        {
        'blob' => image_blob,
        'filename' => @file,
        'type' => @mime_type,
        'is_faked' => false,
        'missing_title' => false
        }
      end
      # Perform logging.
      write_to_log
      
      # Send transformed image as response
      send_data(image_blob, :filename => @file,:type=>@mime_type)
    else
      ### Image not found in repository. Fake image! ###
      
      # Check user preffered action on missing image
      render_error(@user.on_missing_image) and return if not @user.on_missing_image == 200
      
      # Set defaul image size.
      width,height = get_synth_size
      render_400 and return if not width or not height
      
      timer = Time.now.to_f
      # Get item title from solr.
      solr_response = get_title_from_solr
      
      @title_hit = false
      @response_time_title = Time.now.to_f - timer
      text = parse_solr_response(solr_response) # This will change @title_hit to true if a title was found in the solr_response.
      render_error(@user.on_missing_title) and return if @user.on_missing_title != 200 and not(@title_hit)
      
      # Create background
      canvas = Magick::ImageList.new
      canvas.new_image(width, height) do |img|
        self['background_color']='white'
      end
      # Set text properties
      margin,cur_size = calculate_fitting_text_properties(width,height)
      # Create text-image
      text_image = render_cropped_text(text, width-2*margin, height,cur_size) do |img|
        img.gravity = Magick::CenterGravity
        img.format = "PNG"
      end
      
      # Set position of text on background
      offset_x = ((width - text_image.columns) / 2).floor
      offset_y = ((height - text_image.rows) / 3).floor
      text_image.page = Magick::Rectangle.new(text_image.columns,text_image.rows,offset_x,offset_y)
      
      # Combine text with background
      canvas << text_image
      @transformed_image = canvas.flatten_images
      
      # Crop image
      #render_400 and return if not crop_image
      # Scale image
      #scale_image
      
      # Rotate image
      rotate_image
      
      # Convert image to correct format
      image_blob = convert_image_to_blob
      
      # Notice the 'timer' variable is set in connection with solr response time calculation (but placement is identical for image_synth_time calculation).
      @image_synth_time = Time.now.to_f - timer #TODO: should this come before or after writing to cache ?
      
      # Cache image (if not already cached)
      Rails.cache.fetch @cache_id,:expires_in => (ImageDeliveryService::Application.config.cache_duration).minute do
        {
        'blob' => image_blob,
        'filename' => @file,
        'type' => @mime_type,
        'is_faked' => true,
        'missing_title' => (@title_hit ? false : true)
        }
      end
      
      # Perform logging.
      write_to_log
      
      # Send transformed image as response
      send_data(image_blob, :filename => @file, :type=>@mime_type)
    end
  end
  
  ### Error Messages ###
  private
  def render_error(code)
    if code == 400
      render_400
    elsif code == 404
      render_404
    else
      render_404 # Render 404 in case of unknown error code.
    end
  end
  
  private
  def render_400(perform_log=true)
    # Perform logging.
    write_to_log if perform_log
    # Render
    render :file => "#{Rails.root}/public/400", :status => :bad_request, :formats => :html
  end
  
  private
  def render_401
    #TODO: should we log something on unauthorized attempts ???
    render :file => "#{Rails.root}/public/401", :status => :unauthorized, :formats => :html
  end
  
  private
  def render_404(perform_log=true)
    # Perform logging.
    write_to_log if perform_log
    # Render
    render :file => "#{Rails.root}/public/404", :status => :not_found, :formats => :html
  end
  
  private
  def render_415
    render :file => "#{Rails.root}/public/415", :status => :unsupported_media_type, :formats => :html
  end
  
  private
  def render_501
    #TODO: should we log something on requests for features that haven't been implemented ?
    render :file => "#{Rails.root}/public/501", :status => :not_implemented, :formats => :html
  end
end
