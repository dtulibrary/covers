require './cover_helper.rb' #TODO: make this non-relative

class Amazon
  include CoverHelper
  include ISBNControl
  
  SOURCE_NAME = "amazon"
  
  def initialize() 
    
  end      
  
  def harvest(id_list)
    id_list.each do |id|
      id = isbn_convert(id) unless id.length == 10
      process_cover(id,"http://ecx.images-amazon.com/images/P/#{id}.01.png", SOURCE_NAME) if id
    end
  end
  
  def isbn_convert(id)  
    if id.length == 13
      isbn10 = convert_to_10(id)
      return isbn10 unless isbn10.empty?
    end
    return false
  end 
end

#The original perl script did not in fact do anything when parsed a valid isbn10, only converted isbn13. 
#isbn10 seems to work nicely though, so added the functionality until convinced otherwise.