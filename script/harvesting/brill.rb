require './cover_helper.rb' #TODO: make this non-relative

class Brill #This is NOT done
  include CoverHelper
  
  def initialize() 
    
  end
  
  def make_sources_list
    #TODO: parse the csv from get_sources
  end
  
  def get_sources
    journal_list, book_list = ''
    is_success, body = http_get('http://booksandjournals.brillonline.com/openurl/kbart/journals')
    journal_list = body.to_s if success
    is_success body = http_get('http://booksandjournals.brillonline.com/openurl/kbart/books')
    book_list = body.to_s if success
    return journal_list, book_list
  end      
  
end
