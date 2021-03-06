require 'spec_helper'
#include WebMock::API

describe "Apis" do

  fixtures :users
  
  before(:all) do

    ImageDeliveryService::Application.configure do
      config.imagerepository[:url] = "http://localhost"
      config.imagerepository[:service_location_journal] = "/some_path/"
    end    

    @api_key_invalid = "asndaspodkjahsda"
    @img_journal = "#{Rails.application.config.imagerepository[:url]}#{Rails.application.config.imagerepository[:service_location_journal]}"
    
    @issn = "09064710"
    image_location = "app/assets/images"
    @image_blob = File.open(File.join(image_location, @issn+".png") , "rb").read
  end

  describe "API info requests" do
    
    it "should contain IIIF compliance level header in response" do
      stub = WebMock.stub_request(:get, @img_journal + @issn).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "#{@image_blob}", :headers => { })
      get("api/#{users(:testuser).api_key}/#{@issn}/info.xml")
      response.header['X-Link'].should include Rails.application.config.iiif_compliance
      stub.should have_been_requested
      WebMock.reset!
    end
    
    it "should return XML" do
      WebMock.stub_request(:get, @img_journal + @issn).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "#{@image_blob}", :headers => { })
      get("api/#{users(:testuser).api_key}/#{@issn}/info.xml")
      response.header['Content-Type'].should include 'application/xml'
    end
    
    it "should return JSON" do
      WebMock.stub_request(:get, @img_journal + @issn).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "#{@image_blob}", :headers => { })
      get("api/#{users(:testuser).api_key}/#{@issn}/info.json")
      response.header['Content-Type'].should include 'application/json'
    end
  end
  
  describe "API image requests" do
    
    it "should contain IIIF compliance level header in response" do
      stub = WebMock.stub_request(:get, @img_journal + @issn).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "#{@image_blob}", :headers => { })
      get("api/#{users(:testuser).api_key}/#{@issn}/native.png")
      response.header['X-Link'].should include Rails.application.config.iiif_compliance
      response.header['Content-Type'].should include 'image/png'
    end
  end

  describe "Unauthorized requests" do
    
    it "should return 401 Unauthorized" do
      get("api/#{@api_key_invalid}/09064710/info.xml")
      #page.should have_content(ERROR_401)
      #response.should render_template("#{Rails.root}/public/401.html")
      response.code.should eq("401")
    end
    
    it "should return 401 Unauthorized" do
      get("api/#{@api_key_invalid}/09064710/native.png")
      #page.should have_content(ERROR_401)
      #response.should render_template("#{Rails.root}/public/401.html")
      response.code.should eq("401")
    end
  end

  describe "Bad request - invalid 'region' parameter" do
    
    before(:all) do
      WebMock.stub_request(:get, @img_journal + @issn).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "#{@image_blob}", :headers => { })
    end

    # Region begins outside the image
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/pct:110,90,10,10/,120/0/native.png"
      response.code.should eq("400")
    end
    
    # Region parameter breaks the accepted (region) parameter structure
    # Structure => 'pct:x,y,width,height'
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/pct:90,90x,10,10/,120/0/native.png"
      response.code.should eq("400")
    end
    
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/pct:90,90,1x0,10/,120/0/native.png"
      response.code.should eq("400")
    end
    
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/pct:90,90,10,x10/,120/0/native.png"
      response.code.should eq("400")
    end
    
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/xpct:90,90,10,10/,120/0/native.png"
      response.code.should eq("400")
    end
    
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/pct:90,90,10,10x/,120/0/native.png"
      response.code.should eq("400")
    end
    #TODO: add the rest of the possibilities...
  end

  describe "Bad request - invalid 'size' parameter" do
    
    before(:all) do
      WebMock.stub_request(:get, @img_journal + @issn).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "#{@image_blob}", :headers => { })
    end

    # structure => ',height'
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/full/,120x/0/native.png"
      response.code.should eq("400")
    end
    
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/full/,12x0/0/native.png"
      response.code.should eq("400")
    end
    
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/full/,x120/0/native.png"
      response.code.should eq("400")
    end
    
    # structure => 'width,'
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/full/120x,/0/native.png"
      response.code.should eq("400")
    end
    
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/full/12x0,/0/native.png"
      response.code.should eq("400")
    end
    
    it "should return the 'Bad request (400) error page'" do
      get "/api/#{users(:testuser).api_key}/#{@issn}/full/x120,/0/native.png"
      response.code.should eq("400")
    end
    #TODO: add the rest of the possibilities...
  end
  #TODO: add specs for the 'rotation' parameter
end
