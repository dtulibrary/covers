require './cover_helper.rb' #TODO: make this non-relative

class RSC
  include CoverHelper
  
  attr_accessor :source_list
  
  # Basic config
  SOURCE_NAME = "rsc"
  
  # URLs
  BASE_URL = "http://pubs.rsc.org"
  
  # Regular expressions
  REGEX_HREF_JOURNAL = /href="(\/en\/journals\/journal\/\w+\?type=archive&amp;issnprint=(....-....)(&amp;issnonline=(....-....))?)"/
  REGEX_SRC_IMAGE_JOURNAL = /(http:\/\/pubs\.rsc\.org\/services\/images\/rscpubs\.eplatform\.service\.freecontent\.imageservice\.svc\/imageservice\/image\/CoverIssue\?id=\w+&tobecached=true&issueid=\w+)/
  REGEX_SRC_IMAGE_BOOK = /(http:\/\/pubs\.rsc\.org\/services\/images\/RSCpubs\.ePlatform\.Service\.FreeContent\.ImageService\.svc\/ImageService\/image\/BookCover\?id=.+)/
  
  #TODO: parse excel document !
  
  def initialize()
    @source_list = Hash.new
  end
  
  def harvest
    load_source_list
    puts "#{@source_list.keys().size} cover images were found !"
    process_covers
  end
  
  def load_source_list()
    is_success, html = http_get("#{BASE_URL}/en/journals/getatozresult?key=title&value=all")
    puts "FAILURE: Base URL not reachable" and return if not is_success
    html.scan(REGEX_HREF_JOURNAL).each do |href|
      url = href[0]
      pissn = href[1].gsub(/-/,'')
      eissn = href[3].gsub(/-/,'') unless href[3] == nil
      if(pissn)
        @source_list[pissn] = url if not @source_list.has_key?(pissn)
      elsif(eissn)
        @source_list[eissn] = url if not @source_list.has_key?(eissn)
      end
    end
  end

  def process_covers()
    @source_list.keys().each do |id|
      is_success, html = http_get_follow_redirect("#{BASE_URL}#{@source_list[id]}",BASE_URL)#http_get("#{BASE_URL}#{@source_list[id]}")
      puts "FAILURE: Base URL not reachable" and continue if not is_success
      if id.size == 8
        html.scan(REGEX_SRC_IMAGE_JOURNAL).flatten.each do |image_url|
          #puts "Found image at: '#{image_url}'"
          process_cover(id,"#{image_url}", SOURCE_NAME, force_content_type="jpg")
        end
      else
        html.scan(REGEX_SRC_IMAGE_BOOK).flatten.each do |image_url|
          process_cover(id,"#{image_url}", SOURCE_NAME, force_content_type="jpg")
        end
      end
    end
  end
    
end