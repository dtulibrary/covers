module ISBNControl
  
  def check_digit_10(isbn)
    # Check that the id is numeric
    return unless isbn =~ /^\d+$/
    sum = 0
    (0..8).each do |i|
      c = isbn[i].to_i
      w = i + 1
      sum += w * c
    end
    r = sum % 11
    if r == 10
      return 'X'
    else
      return r
    end
  end
  
  def check_digit_13(isbn)
    sum = 0
    (0..11).each do |i|
      c = isbn[i].to_i
      w = 1
      if i % 2 == 1
        w = 3
      end
      sum += w * c
    end
    r = (10 - (sum % 10) % 10)
    return r.to_s
  end
  
  def validate(isbn)
    valid = false
    isbn.gsub!('-','')
    if isbn.size == 10
      valid = true if check_digit_10(isbn[0..8])[0].ord == isbn[9].upcase[0].ord
    elsif isbn.size == 13
      isbn.gsub!(/^X/i,'0'); # So that fake ISBNs validate.
      valid = true if check_digit_13(isbn[0..11])[0].ord == isbn[12].upcase[0].ord
    end
    return valid
  end
  
  def convert_to_10(isbn)
    if validate(isbn)
      prefix = check = ''
      isbn.gsub!('-','')
      if isbn.size == 10
        prefix = isbn
      elsif isbn.size == 13 and isbn =~ /^978/
        prefix = isbn[3..8]
        check = check_digit_10(prefix)
      end
      return "#{prefix}#{check}"
    end
    return ''
  end
  
  def convert_to_13(isbn)
    prefix = check = ''
    if validate(isbn)
      isbn.gsub!('-','')
      if isbn.size == 13
        prefix = isbn
      elsif isbn.size == 10
        prefix = "978#{isbn[3..8]}"
        check = check_digit_13(prefix)
      end
    end
    return "#{prefix}#{check}"
  end
  
  
end