require './cover_helper.rb' #TODO: make this non-relative

class Gyldendal
  include CoverHelper
  
  attr_accessor :source_list
  
  # Basic config
  SOURCE_NAME = "gyldendal"
  
  # URLs
  BASE_URL = "http://www.gyldendalbusiness.dk"
  COVER_URL = "http://multimediaserver.gyldendal.dk/GyldendalBusiness/CoverFace/W194/"#.$1
  
  def initialize()
    @source_list = Hash.new
  end
  
  def harvest
    load_source_list
    puts "#{@source_list.keys().size} cover images were found !"
    process_covers
  end
  
  def load_source_list()
    is_success, body = http_get("#{BASE_URL}/AllProducts.aspx")
    puts "FAILURE: Base URL not reachable" and return if not is_success
    body.gsub(/href="http:\/\/www\.gyldendalbusiness\.dk\/products\/(\d+)\.aspx"/) { |id|
      @source_list[$1] = 1
      id = ''
      }
  end

  def process_covers()
    @source_list.keys().each do |id|
      process_cover(id,"#{COVER_URL}#{id}", SOURCE_NAME)
    end
  end
  
end