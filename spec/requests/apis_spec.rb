require 'spec_helper'

describe "Apis" do
=begin
  fixtures :users
  ERROR_400 = "The parameters in your request were invalid."
  ERROR_401 = "Missing or invalid API key"
  API_KEY_INVALID="asndaspodkjahsda"
  
  describe "API info requests" do
    it "should contain IIIF compliance level header in response" do
      get("api/#{users(:testuser).api_key}/09064710/info.xml")
      response.header['X-Link'].should include API_CONFIG['iiif_compliance']['header']
    end
  end
  describe "API image requests" do
    it "should contain IIIF compliance level header in response" do
      get("api/#{users(:testuser).api_key}/09064710/native.png")
      response.header['X-Link'].should include API_CONFIG['iiif_compliance']['header']
    end
  end

  describe "Unauthorized requests" do
    it "should contain error message" do
      get("api/#{API_KEY_INVALID}/09064710/info.xml")
      page.should have_content(ERROR_401)
    end
    it "should contain error message" do
      get("api/#{API_KEY_INVALID}/09064710/native.png")
      page.should have_content(ERROR_401)
    end
  end
=end

=begin
  describe "Get repository image" do
    it "should find image from repository" do
      # Assumes that the image connected with this issn number is converted to a .PNG image.
      # Last verified at: 2 July 2012
      get("api/09064710/full/,120/0/native.png")
      response.header['Content-Type'].should include 'image/png'
    end
  end
  
  describe "Create image when not present in repository image" do
    it "should find image from repository" do
      # Assumes that this issn number doesn't exist
      # Last verified at: 2. July 2012
      get("api/99999999/full/,120/0/native.png")
      response.header['Content-Type'].should include 'image/png'
    end
  end
  
  describe "Verify that 'index' only is accessed as intended" do
    it "it should not accept request to 'index' without parameters (going through the intended route)" do
      visit '/api/index'
      page.should have_content(ERROR_400)
    end
  end
  
  describe "Bad request - invalid 'id' parameter" do
    # A non-digit character is present in 'id'
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710x/full/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/0906x4710/full/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/x09064710/full/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    # Invalid number of digits in id (9 != 8 || 13)
    it "should return the 'Bad request (400) error page'" do
      visit '/api/090647100/full/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    # Invalid number of digits in id (14 != 8 || 13)
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710098765/full/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
  end
  
  describe "Bad request - invalid 'region' parameter" do
    # Region begins outside the image
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/pct:110,90,10,10/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    # Region parameter breaks the accepted (region) parameter structure
    # Structure => 'pct:x,y,width,height'
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/pct:90,90x,10,10/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/pct:90,90,1x0,10/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/pct:90,90,10,x10/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/xpct:90,90,10,10/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/pct:90,90,10,10x/,120/0/native.png'
      page.should have_content(ERROR_400)
    end
    #TODO: add the rest of the possibilities...
  end
  
  describe "Bad request - invalid 'size' parameter" do
    # structure => ',height'
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/full/,120x/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/full/,12x0/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/full/,x120/0/native.png'
      page.should have_content(ERROR_400)
    end
    # structure => 'width,'
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/full/120x,/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/full/12x0,/0/native.png'
      page.should have_content(ERROR_400)
    end
    it "should return the 'Bad request (400) error page'" do
      visit '/api/09064710/full/x120,/0/native.png'
      page.should have_content(ERROR_400)
    end
    #TODO: add the rest of the possibilities...
  end
=end
  #TODO: add specs for the 'rotation' parameter
end
