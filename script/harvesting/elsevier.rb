require './cover_helper.rb' #TODO: make this non-relative
require 'spreadsheet'

class Elsevier
  include CoverHelper
  
  attr_accessor :source_list, :spreadsheet_dict, :spreadsheet_header
  
  # Basic config
  SOURCE_NAME = "elsevier"
  
  # URLs
  BASE_URL = "http://covers.elsevier.com"
  KNOWN_COVER_URL = "#{BASE_URL}/165_FW/"
  KNOWN_LARGE_COVER_URL = "#{BASE_URL}/large_FW/"
  PREFFERED_COVER_URL = "http://www.extranet.elsevier.com/inca_covers_store/issn/"
  
  # Spreadsheet
  SPREADSHEET_URL = "http://cdn.elsevier.com/assets/excel_doc/0003/109137/Pricelist2013EUR.xls"
  SPREADSHEET_FILE = "elsevier_journals.xls"
  SPREADSHEET_WORKSHEET = "Europe"
  
  # Regular expressions
  REGEX_HREF_ID_ISBN = /href="([0-9x]{13}).jpg/i
  REGEX_HREF_ID_ISSN = /href="([0-9x-]{8,9})\.jpg"/i
  
  def initialize()
    @source_list = Hash.new
    @spreadsheet_header = Array.new
    @spreadsheet_dict = Hash.new
  end
  
  def harvest
    load_source_list
    puts "#{@source_list.keys().size} cover images were found !"
    process_covers
  end
  
  def load_source_list()
    # Load excel sheet
    http_get_file(SPREADSHEET_URL, SPREADSHEET_FILE)
    Spreadsheet.open(SPREADSHEET_FILE) do |book|
      book.worksheet(SPREADSHEET_WORKSHEET).each do |row|
        break if row[0].nil?
        if @spreadsheet_header.size == 0
          @spreadsheet_header = row.join('||').split('||') # a bit of a hack, but ensures correct result. #TODO: find a more pretty way to do it !
        else
          issn_index = @spreadsheet_header.index("ISSN")
          puts "Error: ISSN index not found !" and break if issn_index < 0
          @spreadsheet_dict[row[issn_index]] = row.join('||').split('||') # a bit of a hack, but ensures correct result. #TODO: find a more pretty way to do it !
        end
      end
    end
    
    # Delete excel sheet after use
    delete_file(SPREADSHEET_FILE)
    
    # Load known covers
    is_success, html = http_get(KNOWN_COVER_URL)
    if is_success
      ### Extract pending ids ###
      html.scan(REGEX_HREF_ID_ISBN).flatten.each do |id|
        @source_list[id] = "#{KNOWN_COVER_URL}#{id}.jpg" if not @source_list.has_key?(id) 
      end
      html.scan(REGEX_HREF_ID_ISSN).flatten.each do |id|
        @source_list[id] = "#{KNOWN_COVER_URL}#{id}.jpg" if not @source_list.has_key?(id) 
      end      
    end
    # Load known large covers
    is_success, html = http_get(KNOWN_LARGE_COVER_URL)
    if is_success
      ### Extract pending ids ###
      html.scan(REGEX_HREF_ID_ISBN).flatten.each do |id|
        @source_list[id] = "#{KNOWN_LARGE_COVER_URL}#{id}.jpg" if not @source_list.has_key?(id) 
      end
      html.scan(REGEX_HREF_ID_ISSN).flatten.each do |id|
        @source_list[id] = "#{KNOWN_LARGE_COVER_URL}#{id}.jpg" if not @source_list.has_key?(id) 
      end            
    end    
  end

  def process_covers()
    @source_list.keys().each do |id|
      clean_id = id.gsub(/-/,'')
      if @spreadsheet_dict.has_key?(id)
        process_cover(clean_id,"#{PREFFERED_COVER_URL}#{clean_id.upcase}.gif", SOURCE_NAME)
      else
        process_cover(clean_id,@source_list[id], SOURCE_NAME)
      end
    end
    @spreadsheet_dict.keys().each do |id|
      clean_id = id.gsub(/-/,'')
      process_cover(clean_id,"#{PREFFERED_COVER_URL}#{clean_id.upcase}.gif", SOURCE_NAME)
    end
  end
  
end