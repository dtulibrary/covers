require './cover_helper.rb' #TODO: make this non-relative

class AIP
  include CoverHelper
  include ISBNControl
  
  attr_accessor :source_list
  
  # Basic config
  SOURCE_NAME = "aip"
  
  # URLs
  PUBLISHING_LIST_URL = "http://librarians.aip.org/titles.html"
  
  # Regular Expressions
  REGEX_TABLE_ROW = /<tr>(.+?)<\/tr>/mi
  REGEX_ID_LINE = /(Print|Online)( only)?: (....)-(....)/mi
  REGEX_HREF_ID = /<a href="(http:\/\/[^"]+)"/mi
  REGEX_ID_PISSN = /Print( only)?: (....)-(....)/mi
  REGEX_ID_EISSN = /Online( only)?: (....)-(....)/mi
  REGEX_HREF_IMAGE = /<img src='(\/polopoly_fs\/[^']+)' alt='link.+?cover/
  
  def initialize() 
    @source_list = Hash.new
  end      
  
  def harvest()
    load_source_list
    puts "#{@source_list.keys().size} cover images were found !"
    process_covers
  end
  
  def load_source_list
    is_success, body = http_get(PUBLISHING_LIST_URL)
    puts "FAILURE: Publishing URL not reachable" and return if not is_success
    rows = body.scan(REGEX_TABLE_ROW).flatten
    puts "#{rows.size} rows were found !"
    rows.each do |row|
      next if not row =~ REGEX_ID_LINE
      source = Hash.new
      # Find URL
      if row =~ REGEX_HREF_ID
        source['url'] = $1
      end
      # Find ID
      if row =~ REGEX_ID_PISSN
        source['issn'] = "#{$2.downcase}#{$3.downcase}"
      elsif row =~ REGEX_ID_EISSN
        source['issn'] = "#{$2.downcase}#{$3.downcase}"
      end
      @source_list[source['issn']] = source['url'] if(not(source['url'].empty?) and not(source['issn'].empty?))
    end
  end
  
  def get_image_url(id,target)
    is_success, html = http_get(target)
    if is_success
      match = html =~ REGEX_HREF_IMAGE
      return "#{target}/#{$1}" if match and not match.nil?#empty?
    end
    return false
  end
  
  def process_covers
    @source_list.keys().each do |id|
      if not cover_exists(id, SOURCE_NAME)        
        url = get_image_url(id, @source_list[id])
        process_cover(id, url, SOURCE_NAME) if url
      end
    end
  end
  
end