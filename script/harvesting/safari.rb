require './cover_helper.rb' #TODO: make this non-relative
require './isbn_control.rb'

class Safari
  include CoverHelper
  include ISBNControl
  
  attr_accessor :source_list, :pending_ids, :pending_links
  attr_accessor :safari_image_idx, :safari_recurrence_limit
  
  # Basic config
  SOURCE_NAME = "safari"
  
  # URLs
  BASE_URL = "http://my.safaribooksonline.com"
  RSS_URL = "#{BASE_URL}/rss"
  
  # Regular Expressions
  REGEX_OTHER_TITLE = /\/book\/([a-z\/-]+)\/([0-9X]+)/#/my\.safaribooksonline\.com\/book\/([a-z\/-]+)\/([0-9X]+)/ #
  REGEX_CATEGORY_LINK = /\/browse\?category=[a-z\.-]+/
 
  
  def initialize
    @source_list = Hash.new
    @pending_ids = Hash.new
    @pending_links = Hash.new
    @safari_image_idx = '201203-6435'
    @safari_recurrence_limit = 3
  end
  
  def harvest
    load_source_list
    puts "#{@source_list.keys().size} cover images were found !"
    process_covers
  end
  
  def load_source_list
    is_success, body = http_get(RSS_URL)
    puts "FAILURE: Base URL not reachable" and return if not is_success
    
    #  s#<comments>http://my.safaribooksonline.com/([0-9X]+)</comments>##
    
    while(body =~ /<comments>http:\/\/my.safaribooksonline.com\/([0-9X]+)<\/comments>/)
      id = $1
      id2 = convert_to_13(id)
      if id2 != '' and not @source_list.has_key?(id2)
        @source_list[id2] = id
      end
      body.sub!(/<comments>http:\/\/my.safaribooksonline.com\/([0-9X]+)<\/comments>/,"")
    end
    
    puts @source_list
    
    #TODO: a lot more stuff....
    
    # body.gsub(/([0-9x]{13})\.jpg/) { |id|
      # id = id.gsub(/\.jpg/,'')
      # @source_list[id] = 1
      # id = ''
      # }
  end
  
  def lookup_book(identifier)
    
    return false if @safari_recurrence_limit <= 0
    #@safari_recurrence_limit -= 1
    id = id2 = ''
    sleep(1) # Be nice! relax crawling...
    is_success, body = http_get("#{BASE_URL}/#{identifier}?bookview=overview")
    if is_success
      if body =~ /Print ISBN-13:\s+<\/strong><span>([-0-9]+)/
        id = $1
        id.gsub!(/-/,'')
      end
      if body =~ /Web ISBN-13:\s+<\/strong><span>([-0-9]+)/
        id2 = $1
        id2.gsub!(/-/,'')
      end
      extract_ids(body)
    else
      puts "There was an error. http get failed."
    end    
    return is_success
  end
  
  def extract_ids(html)
    ### Extract ids ###
    while(html =~ /static\/(\d+-\d+)-my\/images\/([0-9X]+)\/([0-9X]+)_[a-z]+\.[a-z]+/)
      if $2 == $3
        id = $2
        @safari_image_idx = $1
        id2 = convert_to_13(id)
        if id2 != '' and not @source_list.has_key?(id2)
          @source_list[id2] = id
        end
      end
      html.sub!(/static\/(\d+-\d+)-my\/images\/([0-9X]+)\/([0-9X]+)_[a-z]+\.[a-z]+/,"")
    end
    ### Extract pending links ###
    html.scan(REGEX_CATEGORY_LINK).each do |match|
      link = "#{BASE_URL}#{match}"
      @pending_links[link] = 1 if not @pending_links.has_key?(link) 
    end
    ### Extract pending ids ###
    # puts "Found link set: #{html.scan(REGEX_OTHER_TITLE)}"
    # html.scan(REGEX_OTHER_TITLE).each do |other|
      # link = "my.safaribooksonline.com/book/#{other[0]}/#{other[1]}"
      # #puts "Found link: #{link}"
      # id = convert_to_13(other[1])
      # if id2 != '' and not @pending_ids.has_key?(id)
        # @pending_ids[id] = link
      # end
    # end
    # while(html =~ /my\.safaribooksonline\.com\/book\/([a-z\/-]+)\/([0-9X]+)/)
      # link = "my.safaribooksonline.com/book/#{$1}/#{$2}"
      # puts "Found link: #{link}"
      # id = convert_to_13($2)
      # if id2 != '' and not @pending_ids.has_key?(id)
        # @pending_ids[id] = link
      # end
      # html.sub!(/my\.safaribooksonline\.com\/book\/([a-z\/-]+)\/([0-9X]+)/,"")
    # end
  end
  
  def process_covers()
    stored_images = 0
    @source_list.keys().each do |id|
      is_success = lookup_book(id)
      process_cover(id,"#{BASE_URL}/static/#{@safari_image_idx}-my/images/#{id.upcase}/#{id.upcase}_s.jpg", SOURCE_NAME) if is_success
      stored_images += 1 if is_success
=begin
      ### Lookup book ###
      .$identifier."?bookview=overview
      ### Download ISBN ###
      static/".$self->{safari_image_idx}.
            "-my/images/".uc $id."/".uc $id."_s.jpg",
=end
    end
    
    puts "#{@pending_links.keys().size} pending links were found !"
    @pending_links.keys().each do |link|
      is_success, html = http_get(link)
      if is_success
        #puts "Found link set: #{html.scan(REGEX_OTHER_TITLE)}"
        prev_link = ''
        html.scan(REGEX_OTHER_TITLE).each do |other|
          ### limit redundancy ###
          next if prev_link == other
          prev_link = other
          ### Check and store id ###
          link = "my.safaribooksonline.com/book/#{other[0]}/#{other[1]}"
          #puts "Found link: #{link}"
          id = convert_to_13(other[1])
          if id != '' and not @pending_ids.has_key?(id)
            @pending_ids[id] = link
          end
        end
      end
    end
        
    puts "#{@pending_ids.keys().size} ids found through browsing categories !"
    
    @pending_ids.keys().each do |id|
      # Only lookup book, if it isn'ẗ already in the repository
      if not cover_exists(id)
        is_success = lookup_book(id)
        process_cover(id,"#{BASE_URL}/static/#{@safari_image_idx}-my/images/#{id.upcase}/#{id.upcase}_s.jpg", SOURCE_NAME) if is_success
        stored_images += 1 if is_success
      end
      #puts "BEFORE: #{@pending_ids.keys()}"
      #@pending_ids = @pending_ids.tap { |hs| hs.delete(id) }
      #puts "AFTER: #{@pending_ids.keys()}"
    end
    
    #puts "#{@pending_ids.size} other titles were found at recurrence level 1"
    # while @safari_recurrence_limit > 0# and @pending_ids.size > 0
        # break if @pending_ids.size == 0
        # puts "#{@pending_ids.size} other titles were found at recurrence level #{10-@safari_recurrence_limit}"
        # @pending_ids.keys().each do |id|
          # @pending_ids.keys()
          # is_success = lookup_book(id)
          # process_cover(id,"#{BASE_URL}/static/#{@safari_image_idx}-my/images/#{id.upcase}/#{id.upcase}_s.jpg") if is_success
          # stored_images += 1 if is_success
          # #puts "BEFORE: #{@pending_ids.keys()}"
          # @pending_ids = @pending_ids.tap { |hs| hs.delete(id) }
          # #puts "AFTER: #{@pending_ids.keys()}"
        # end
        # @safari_recurrence_limit -= 1
    # end
    puts "#{stored_images} images were stored !"
  end

  
end