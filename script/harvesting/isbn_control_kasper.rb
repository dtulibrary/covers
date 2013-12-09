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
      if i % 2
        w = 3
      end
      sum += w * c
    end
    r = 10 - (sum % 10)
    if r == 10
      return '0'
    else
      return r
    end
  end
  
  def validate(isbn)
    valid = false
    isbn.gsub!('-','')
    if isbn.size == 10
      valid = true if check_digit_10(isbn[0..8]) == isbn[9].upcase
    elsif isbn.size == 13
      isbn.gsub!(/^X/i,0); # So that fake ISBNs validate.
      valid = true if check_digit_10(isbn[0..11]) == isbn[12].upcase
    end
    return valid
  end
  
  def covert_to_10(isbn)  #TODO: this is not done! OR IS IT!?!?!
    if validate(isbn)
      check, prefix = ''
      isbn.gsub!('-','')
      if isbn.size == 13 && isbn =~ /^978/ #Since isbn13 converted from isbn10 is always prefixed this way
        prefix = isbn[3..11]
        check = check_digit_10(prefix)
      elsif isbn.size == 10
        prefix = isbn
      end
      return "#{prefix}#{check}"
    end
    return ''
  end
  
  def convert_to_13(isbn)
    
    if validate(isbn)
      check, prefix = ''
      isbn.gsub!('-','')
      if isbn.size == 13
        prefix = isbn
      elsif isbn.size == 10
        prefix = '978'+isbn[0..9]
        check = check_digit_13(prefix)
      end
      return "#{prefix}#{check}"   
    end
    return ''
  end
end