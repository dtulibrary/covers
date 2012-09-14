xml.instruct!
xml.info "xmlns" => "http://library.stanford.edu/iiif/image-api/ns/" do
  xml.identifier @id
  xml.width @info_width
  xml.height @info_height
  xml.formats do
    @formats.each do |f|
      xml.format f
    end
  end
  xml.qualities do
    @qualities.each do |a|
      xml.quality a
    end
  end
  xml.profile "http://library.stanford.edu/iiif/image-api/compliance.html#level1"
end