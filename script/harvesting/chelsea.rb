require './cover_helper.rb' #TODO: make this non-relative

class Chelsea
  include CoverHelper
  
  attr_accessor :source_list
  
  # Basic config
  SOURCE_NAME = "chelsea"
  
  # URLs
  BASE_URL = "http://www.chelseagreen.com/covers/"
  
  def initialize()
    @source_list = Hash.new
  end
  
  def harvest
    load_source_list
    puts "#{@source_list.keys().size} cover images were found !"
    process_covers
  end
  
  def load_source_list()
    is_success, body = http_get(BASE_URL)
    puts "FAILURE: Base URL not reachable" and return if not is_success
    body.gsub(/([0-9x]{13})\.jpg/) { |id|
      id = id.gsub(/\.jpg/,'')
      @source_list[id] = 1
      id = ''
      }
  end

  def process_covers()
    @source_list.keys().each do |id|
      process_cover(id,"#{BASE_URL}#{id}.jpg", SOURCE_NAME)
    end
  end
  
        # id_chars = id.split(//)
      # id_chars.pop
      # file_path = id_chars.join('/')
      # continue if File.exists? "#{storage}/#{file_path}/#{id}.jpg"
      # # puts "Trying: #{BASE_URL}#{id}.jpg"
      # is_success, blob = http_get("#{BASE_URL}#{id}.jpg")
      # if is_success
        # store_image_from_blob("#{id_chars.join('/')}", "#{id}.jpg", blob)
      # else
        # puts "Failure: image was not found !"
      # end
  
end