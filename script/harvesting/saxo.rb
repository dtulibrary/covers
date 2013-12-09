require './cover_helper.rb' #TODO: make this non-relative
require 'nokogiri'
require 'open-uri'

class Saxo
  include CoverHelper
  
  # Basic config
  SOURCE_NAME = "saxo"
  
  #URLs
  LIST_URL = "http://www.saxo.com/search/search.aspx?keyword="
  
  def initialize() #TODO: reformat when the helper makes sense
    
  end
  
  def harvest(id_list)
    id_list.each do |id|
      source = download_isbn(id)
      process_cover(id,source,SOURCE_NAME)
    end  
  end
  
  def download_isbn(isbn)
    doc = Nokogiri::HTML(open(LIST_URL+isbn)) #Maybe use a helper method instead
    
    if (doc.to_s =~ / "\d+" - ingen resultater/)
      puts "Isbn not found."
      return
    end
      if( doc.to_s =~ /(http:\/\/images.saxo.com\/ItemImage.aspx\?ItemID=\w+)\&/m )
        link = ("#{$1}&Width=300") #Might wanna use this
        return link
      else
        puts "Failure, no picture."
    end
  end


end

#Where do i get the desired ISBNS?