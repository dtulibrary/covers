require './cover_helper.rb' #TODO: make this non-relative

class Librarything #Doesn't seem to be getting any images :/ Also, librarythings covers seems to stem from amazon.
  include CoverHelper
  
  def initialize(id_list) 
    id_list.each do |id|
      id = isbn_convert(id) unless id.length == 10
      process_cover(id,"http://covers.librarything.com/devkey/7f8cd58d518ad8c5d35f2cb737fb59d7/medium/isbn/#{id}") if id
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
