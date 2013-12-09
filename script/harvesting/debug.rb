require './aip.rb'
require './amazon.rb'
require './chelsea.rb'
require './elsevier.rb'
require './gyldendal.rb'
require './rsc.rb'
require './safari.rb'

harvest = {
  "aip" => {"enabled"=>false, "priority"=>1, "need_ids"=>false, "source_object"=>AIP.new},
  "amazon" => {"enabled"=>false, "priority"=>2, "need_ids"=>true, "source_object"=>Amazon.new},
  "chelsea" => {"enabled"=>true, "priority"=>1, "need_ids"=>false, "source_object"=>Chelsea.new},
  "elsevier" => {"enabled"=>false, "priority"=>1, "need_ids"=>false, "source_object"=>Elsevier.new},
  "gyldendal" => {"enabled"=>false, "priority"=>1, "need_ids"=>false, "source_object"=>Gyldendal.new},
  "rsc" => {"enabled"=>false, "priority"=>1, "need_ids"=>false, "source_object"=>RSC.new},
  "safari" => {"enabled"=>false, "priority"=>1, "need_ids"=>false, "source_object"=>Safari.new}
}

missing_ids = []
#TODO: fetch missing ids from gazo (HTTP request?)

harvest.keys().each do |source|
  # Only proceed with enabled sources
  if harvest[source]["enabled"]    
    # Harvest source
    puts "Harvesting #{source.capitalize}"
    if harvest[source]["need_ids"]
      harvest[source]["source_object"].harvest(missing_ids)
    else
      harvest[source]["source_object"].harvest()
    end
  end
end

puts "Done!"
