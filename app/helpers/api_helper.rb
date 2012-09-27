require 'net/http'
require 'uri'
require 'rsolr'
require 'RMagick'
require 'date'

module ApiHelper
  ### Image manipulation ###
  def crop_image
    if not @region =~ /^full$/
      if @region =~ /^\d+,\d+,\d+,\d+$/
        rectangle = @region.split(',')
        x = rectangle[0].to_i
        y = rectangle[1].to_i
        new_width = rectangle[2].to_i
        new_height = rectangle[3].to_i
        # Verify that cropping is acceptable. Otherwise return "Bad request"
        return false if x >= @transformed_image.columns or y >= @transformed_image.rows
        # Crop image
        if x + new_width > @transformed_image.columns
          new_width = @transformed_image.columns - x
        elsif y + new_height > @transformed_image.rows
          new_height = @transformed_image.rows - y
        end
        @transformed_image = @transformed_image.crop!(x,y,new_width,new_height)
      elsif @region =~ /^pct:\d+,\d+,\d+,\d+$/
        rectangle = @region.gsub!(/pct:/,"")
        rectangle = rectangle.split(',')
        x = (@transformed_image.columns * (rectangle[0].to_i / 100.0))
        y = (@transformed_image.rows * (rectangle[1].to_i  / 100.0))
        # Verify that cropping is acceptable. Otherwise return "Bad request"
        return false if x >= @transformed_image.columns or y >= @transformed_image.rows
        # Crop image
        new_width = (@transformed_image.columns * (rectangle[2].to_i  / 100.0))
        new_height = (@transformed_image.rows * (rectangle[3].to_i  / 100.0))
        if x + new_width > @transformed_image.columns
          new_width = @transformed_image.columns - x
        elsif y + new_height > @transformed_image.rows
          new_height = @transformed_image.rows - y
        end
        @transformed_image = @transformed_image.crop!(x.to_i,y.to_i,new_width.to_i,new_height.to_i)
      end
    end
    return true
  end
  
  def get_synth_size
    if not @size =~ /^full$/
      if @size =~ /^\d+,\d+$/
        dim = @size.split(',')
        new_width = dim[0].to_i
        new_height = dim[1].to_i
        return new_width,new_height
      elsif @size =~ /^\d+,$/
        new_width = @size.sub!(/,/,"").to_i
        new_height = (new_width / 3) * 4
        return new_width,new_height
      elsif @size =~ /^,\d+$/
        new_height = @size.sub!(/,/,"").to_i
        new_width = (new_height / 4) * 3
        return new_width,new_height
      elsif @size =~ /^pct:\d+$/
        scale_factor =  (@size.sub!(/pct:/,"").to_f / 100.0)
        new_height = (@user.default_height.to_f * scale_factor).floor
        new_width = (@user.default_width.to_f * scale_factor).floor
        return new_width,new_height
      elsif @size =~ /^!\d+,\d+$/
        dim = @size.sub!(/!/,"").split(',')
        new_width = dim[0].to_i
        new_height = dim[1].to_i
        return new_width,new_height
      end
      # In case anything goes wrong choose default (shouldn't be possible due to param verification)
      return @user.default_width,@user.default_height
    else
      return @user.default_width,@user.default_height
    end
  end
  
  def scale_image
    if not @size =~ /^full$/
      if @size =~ /^\d+,\d+$/
        dim = @size.split(',')
        new_width = dim[0].to_i
        new_height = dim[1].to_i
        @transformed_image = @transformed_image.scale(new_width,new_height)
      elsif @size =~ /^\d+,$/
        new_width = @size.sub!(/,/,"")
        resize_factor = new_width.to_f / @transformed_image.columns
        @transformed_image = @transformed_image.resize_to_fit(new_width,resize_factor.ceil*@transformed_image.rows)
      elsif @size =~ /^,\d+$/
        new_height = @size.sub!(/,/,"")
        resize_factor = new_height.to_f / @transformed_image.rows
        @transformed_image = @transformed_image.resize_to_fit(resize_factor.ceil*@transformed_image.columns,new_height)
      elsif @size =~ /^pct:\d+$/
        scale_factor =  @size.sub!(/pct:/,"").to_f
        @transformed_image = @transformed_image.scale(scale_factor / 100)
      elsif @size =~ /^!\d+,\d+$/
        dim = @size.sub!(/!/,"").split(',')
        new_width = dim[0].to_i
        new_height = dim[1].to_i
        @transformed_image = @transformed_image.resize_to_fit(new_width,new_height)
      end
    end
  end
  
  def rotate_image
    if not @rotation =~ /^0$/
      if @rotation =~ /^\d+$/
        amount = @rotation.to_i
        @transformed_image = @transformed_image.rotate(amount)
      end
    end
  end
  
  def convert_image_to_blob
    if @file_extension == 'png'
      return @transformed_image.to_blob{self.format="PNG"}
    elsif @file_extension == 'jpg'
      return @transformed_image.to_blob{self.format="JPG"}
    else
      puts "Error not accepted format!"
    end
  end
  
  ### Fake image ###
  def get_title_from_solr
    response = false #TODO: this is for test purposes only! should be deleted later!
=begin 
    solr = RSolr.connect :url => API_CONFIG['solr']['url']
    request_handler = ( @id.length == 8 ? API_CONFIG['solr']['request_handler_journal'] : API_CONFIG['solr']['request_handler_book'])
    response = solr.get request_handler, :params => { # select?q=....
       :q=>@id, # Query - should point to post with issn/isbn
    }
=end
    return response
  end
  
  def parse_solr_response(response)   
    text = 'No image'
    if response
      if(not(response["response"] and response["response"]["docs"]))
        # Check user preffered action on missing title
        return text if not @user.on_missing_title == 200
      elsif(not(response["response"]["docs"].empty? or response["response"]["docs"][0].keys.empty? or response["response"]["docs"][0]["title"].empty?))
        text = response["response"]["docs"][0]["title"][0]
        @title_hit = true
        return text
      else
        # Check user preffered action on missing title
        return text# if not @user.on_missing_title == 200
      end
    else
      # Check user preffered action on missing title
      return text# if not @user.on_missing_title == 200
    end
  end
  
  def calculate_fitting_text_properties(width,height)
    min_text_size = 10
    max_text_size = 100
    margin = (width.to_f * 0.1).floor
    w = width - 2*margin
    cur_size = max_text_size
    expected_width = width + 1
    line_length = 20
    # Calculate fitting text size in relation to image size.
    while expected_width > width and cur_size > min_text_size
      expected_width = 2*margin + line_length * cur_size
      if expected_width > width
        cur_size -= 1
      end
    end
    return margin,cur_size
  end
  
  ### Log request/response info ###
  def write_to_log
    @total_time = Time.now.to_f - @start_time
    CACHE_LOG.info log_msg
  end
  
  def log_msg
=begin
    Cache hit/miss
    Image repository hit/miss
    Title hit/miss
    Response time for image repository (in case of cache miss)
    Response time for title index (in case of image repository miss)
    Image processing time (in case of cache miss, but image repository hit)
    Image synthesize time (in case of image repository miss)
    Total response time 
=end
    info = Array.new
    info << "cache_id="+(@cache_id ? @cache_id : "bad request")
    info << "cache_hit="+(@cache_hit ? "yes" : "no") # @cache_hit => true || false
    info << "image_hit="+(@image_hit ? "yes" : "no") # @image_hit => true || false    
    info << "title_hit="+(@title_hit ? "yes" : "no") if not @image_hit # @title_hit => true || false
    info << "response_time_image="+format("%.5fs",@response_time_image) if @response_time_image
    info << "response_time_title="+format("%.5fs",@response_time_title) if @response_time_title
    info << "image_proc_time="+format("%.5fs",@image_proc_time) if @image_proc_time
    info << "image_synth_time="+format("%.5fs",@image_synth_time-@response_time_title) if @image_synth_time and @response_time_title
    info << "total_time="+format("%.5fs",@total_time) if @total_time
    msg = ""
    info.each_with_index do |m,i|
      msg += m + (i == info.size-1 ? '' : ',')
    end
    return msg
  end
  ### Repository requests ###
  def fetch_image
    timer = Time.now.to_f
    uri = URI.parse(API_CONFIG['imagerepository']['url']+@service_location+@id.downcase)
    response = Net::HTTP.get_response(uri)
    @response_time_image = Time.now.to_f - timer
    if response.code.to_i == 200
      return true,response.body # return image
    else
      return false,''
    end
  end
  
end
