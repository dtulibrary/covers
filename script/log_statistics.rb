### Configuration variables ###
LOG_FILE = "cache.log"
IMAGES_FILE = "missing_images.log"
PERFORMANCE_FILE = "performance_issues.log"

total_lines = 0
image_miss_lines = 0
cache_ids = Hash.new
performance_issue_number = 0
performance_issues = Hash.new
performance_issues_lines = Hash.new
cache_hits = 0

### Traverse file ###
file = File.new(LOG_FILE, "r")
while (line = file.gets)
    line.gsub!(/\n/,"")
    log_hash = Hash.new
    total_lines = total_lines + 1
    ### Remove timestamp and log level (INFO) ###
    log_hash['timestamp'] = line+""
    log_hash['timestamp'] =~/^.*INFO\s/
    log_hash['timestamp'].gsub!(/\s+INFO\s.*/,"")
    line.sub!(/^.*INFO\s/,"")
    ### Fix log so cache_id doesn't disrupt finding of log keys/attributes. ###
    line =~ /cache_id=(.*\.(png|jpg))/ # Add additional formats to this regex if the imageservice functionality is extended.
    cid = $1.sub!(/,/,';')
    line.sub!(/cache_id=(.*\.png)/,"cache_id=#{cid}")
    ### Load log attributes ###
    line.split(',').each do |attribute|
      pair = attribute.split('=')
      log_hash[pair[0]] = pair[1]
    end
    ### Verify that the line contains the required attributes ###
    if not log_hash.has_key?('image_hit')
      puts "ERROR ! Log entry doesn't have 'image_hit' key"
      puts "#{total_lines}: #{line}"
      next
    elsif not log_hash.has_key?('cache_id')
      puts "ERROR ! Log entry doesn't have 'cache_id' key"
      puts "#{total_lines}: #{line}"
      next
    end
    ### Check if the request was a cache hit ###
    if log_hash['cache_hit'] == 'yes'
      cache_hits += 1
    end
    ### Check if the requested image was found in the repository ###
    if log_hash['image_hit'] == 'no'
      image_miss_lines += 1
      cache_id = log_hash['cache_id'].split('||')[0] # Actually issn/isbn due to .split('||')[0]
      if cache_ids.has_key?(cache_id)
        cache_ids[cache_id] += 1
      else
        cache_ids[cache_id] = 1
      end
    end
    ### Check if the response-time was within acceptable limits ###
    log_hash['total_time'] = log_hash['total_time'].sub(/s/,"").to_f
    if log_hash['total_time'] > 1.0
      cache_id = log_hash['cache_id']
      performance_issue_number += 1
      if performance_issues.has_key?(cache_id)
        performance_issues[cache_id] += 1
        performance_issues_lines[cache_id] << {'line' => line, 'log_hash' => log_hash, 'total_time' => log_hash['total_time']}
      else
        performance_issues[cache_id] = 1
        performance_issues_lines[cache_id] = Array.new
        performance_issues_lines[cache_id] << {'line' => line, 'log_hash' => log_hash, 'total_time' => log_hash['total_time']}
      end
    end
end
file.close
### Sort performance issues ###
performance_issues = performance_issues.sort_by { |k, v| v }.reverse

### Top 10 performance issues (frequency) ###
performance_issues[0..5].each do |id,hits|
  puts "ID = #{id} - HITS = #{hits}"
  performance_issues_lines[id].each do |issue|
    #puts issue[:total_time]
    puts "\t#{issue['total_time']}s (#{issue['log_hash']['timestamp']})"# (#{issue['line']})"
  end
end
puts "There were #{total_lines} in the log"
puts "#{format("%.2f",(performance_issue_number.to_f/total_lines.to_f)*100)} % or #{performance_issue_number} / #{total_lines} requests resulted in a performance issue"
puts "#{performance_issues.size} unique requests resulted in a performance issue  (based on cahce_id)"

File.open(PERFORMANCE_FILE, 'w') { |f|
  f.write("A performance issue is defined as a request with response time > 1s\n")
  f.write("#{format("%.2f",(performance_issue_number.to_f/total_lines.to_f)*100)} % or #{performance_issue_number} / #{total_lines} requests resulted in a performance issue\n")
  f.write("#{performance_issues.size} unique requests resulted in a performance issue  (based on cahce_id)\n")
  performance_issues.each do |id,hits|
  f.write("ID = #{id} - HITS = #{hits}\n")
  performance_issues_lines[id].each do |issue|
    #puts issue[:total_time]
    f.write("\t#{issue['total_time']}s (#{issue['log_hash']['timestamp']})\n")
  end
end
}

### Sort missing images ###
cache_sorted = cache_ids.sort_by { |k, v| v }.reverse
### Top 10 missing images ###
cache_sorted[0..10].each do |id,hits|
  #issn = id.split('||')[0]
  while id.size < 13
    id += " "
  end
  puts "ID = #{id} - HITS = #{hits}"
end
puts "There were #{total_lines} in the log"
puts "#{format("%.2f",(cache_hits.to_f/total_lines.to_f)*100)} % or #{cache_hits} / #{total_lines} requests resulted in a cache hit"
puts "#{format("%.2f",(image_miss_lines.to_f/total_lines.to_f)*100)} % or #{image_miss_lines} / #{total_lines} requests resulted in a missing image"
puts "#{cache_ids.keys().size} images were missing (based on issn/isbn)" # (based on cahce_id and may thus contain duplicates)"

### Write statistics to the output file ###
File.open(IMAGES_FILE, 'w') { |f|
  cache_sorted.each do |id,hits|
    #issn = id.split('||')[0]
    while id.size < 13
      id += " "
    end
    f.write("ID = #{id} - HITS = #{hits}\n")
  end
}

### Notes on log file structure ###
=begin
 def log_msg

    # Cache hit/miss
    # Image repository hit/miss
    # Title hit/miss
    # Response time for image repository (in case of cache miss)
    # Response time for title index (in case of image repository miss)
    # Image processing time (in case of cache miss, but image repository hit)
    # Image synthesize time (in case of image repository miss)
    # Total response time

    info = Array.new
    info << "api_key="+(@api_key ? @api_key : "unauthorized request")
    info << "request_ip="+(@request_ip ? @request_ip : "unknown ip")
    info << "cache_id="+(@cache_id ? @cache_id : "bad request")
    info << "cache_hit="+(@cache_hit ? "yes" : "no") # @cache_hit => true || false
    info << "image_hit="+(@image_hit ? "yes" : "no") # @image_hit => true || false
    info << "title_hit="+(@title_hit ? "yes" : "no") if not @image_hit # @title_hit => true || false
    info << "response_time_image="+format("%.5fs",@response_time_image) if @response_time_image
    info << "response_time_title="+format("%.5fs",@response_time_title) if @response_time_title
    info << "image_proc_time="+format("%.5fs",@image_proc_time) if @image_proc_time
    info << "image_synth_time="+format("%.5fs",@image_synth_time-@response_time_title) if @image_synth_time and @response_time_title
    info << "total_time="+format("%.5fs",@total_time) if @total_time
    msg = ""
    info.each_with_index do |m,i|
      msg += m + (i == info.size-1 ? '' : ',')
    end
    return msg
  end 
=end