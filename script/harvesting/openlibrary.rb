require './cover_helper.rb' #TODO: make this non-relative

class OpenLibrary 
  include CoverHelper
  
  def initialize(id_list) 
    id_list.each do |id|
      process_cover(id,"http://covers.openlibrary.org/b/isbn/#{id}-M.jpg?default=false") if id.length == 13 
    end
  end      
end
