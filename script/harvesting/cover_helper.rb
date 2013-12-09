require 'net/http'
require 'uri'
require 'fileutils'
require 'RMagick'
require './isbn_control.rb'

module CoverHelper
  include ISBNControl
  
  IMAGE_EXTENSIONS=["jpg","tif","png","gif"]
  
  ### CONVENIENCE FUNCTIONS ###
  
  # Perform HTTP Get request  
  def http_get(target)
    uri = URI.parse(target)
    response = Net::HTTP.get_response(uri)
    if response.code.to_i == 200
      return true, response.body, response["Content-Type"] # return html
    else
      puts "HTTP Error code: #{response.code}, msg=#{response.msg}, url=#{target}"
      return false,'', ''
    end
  end
  
  def http_get_follow_redirect(target,redirect_prefix='')
    uri = URI.parse(target)
    response = Net::HTTP.get_response(uri)
    case response
    when Net::HTTPSuccess then
      return true, response.body, response["Content-Type"] # return html
    when Net::HTTPRedirection then
      puts "Redirected to Location = '#{redirect_prefix}#{response['location']}"
      return http_get("#{redirect_prefix}#{response['location']}") # Follow redirect (once)
    else
      puts "HTTP Error code: #{response.code}, msg=#{response.msg}, url=#{target}"
      return false,'', ''
    end
  end
  
  # Perform HTTP Get request and store body as a file
  def http_get_file(target, storage_filename)
    uri = URI(target)
    f = open(storage_filename,"w")
    begin
      Net::HTTP.start(uri.host, uri.port){|http|
        http.request_get(target) do |resp|
            resp.read_body do |segment|
                f.write(segment)
            end
        end
      }
    ensure
        f.close()
    end
  end
  
  # Delete the file with the given filename
  def delete_file(filename)
    File.delete(filename)
  end
  
  # Translate mime type to file extension
  def mime_to_extension(mime)
    if mime =~ /image\/jpeg/i
      return "jpg"
    elsif mime =~ /image\/png/i
      return "png"
    elsif mime =~  /image\/tiff/i
      return "tif"
    elsif mime =~  /image\/gif/i
      return "gif"
    end
    puts "Extension not found !"
    return ""
  end
  
  ### PROCESSING FUNCTIONS ###
  def process_cover(id, image_url, source, force_content_type=nil)
    storage = get_storage_base
    id_chars = id.split(//)
    id_chars.pop
    id_chars = id_chars.join('').scan(/.{2,3}/)
    file_path = id_chars.join('/')
    IMAGE_EXTENSIONS.each do |ext|
        return if File.exists? "#{storage}/#{file_path}/#{id}_#{source}.#{ext}"
    end
    is_success, blob, content_type = http_get(image_url)
    if is_success
      store_image_from_blob("#{id_chars.join('/')}", "#{id}_#{source}.#{(force_content_type ? force_content_type : mime_to_extension(content_type))}", blob)
      #TODO: insert image score into database
      # score = get_score_from_blob(blob)
      # insert_score_into_db(id, source, score) if score != nil #TODO: 'create insert_score_into_db' function
    else
      puts "Failure: image was not found !"
    end
  end
  
  def cover_exists(id, source)
    storage = get_storage_base
    id_chars = id.split(//)
    id_chars.pop
    file_path = id_chars.join('/')
    IMAGE_EXTENSIONS.each do |ext|
        return true if File.exists? "#{storage}/#{file_path}/#{id}_#{source}.#{ext}"
    end
    return false
  end
  
  ### RANKING / SCORING FUNCTIONS ###
  def get_score_from_file(id, source)
    storage = get_storage_base
    id_chars = id.split(//)
    id_chars.pop
    id_chars = id_chars.join('').scan(/.{2,3}/)
    file_path = id_chars.join('/')
    # Find image extension
    content_type = nil
    IMAGE_EXTENSIONS.each do |ext|
        content_type=ext and break if File.exists? "#{storage}/#{file_path}/#{id}_#{source}.#{ext}"
    end
    return nil if content_type == nil
    # Load image
    image = Magick::Image::read("#{storage}/#{file_path}/#{id}_#{source}.#{ext}").first
    # Return score
    return calculate_score(image)
  end
  
  def get_score_from_blob(image_data)
    # Load image
    image = Magick::Image::from_blob(image_data).first
    # Return score
    return calculate_score(image)
  end
  
  def calculate_score(image)
    width = image.columns
    height = image.rows
    return width*height
  end

  ### STORAGE FUNCTIONS ###
  def get_storage_base
    #return "/san/image_repos" #TODO: use this for production
    return "/home/corthmann/image_repos"
  end
  
  def create_storage_path(path)
    FileUtils.mkdir_p path
  end
  
  def store_image_from_blob(path, filename, blob)
    path = "#{get_storage_base}/#{path}"
    create_storage_path(path)
    File.open("#{path}/#{filename}", 'w') do |f|
      f.write blob
    end
  end 
end