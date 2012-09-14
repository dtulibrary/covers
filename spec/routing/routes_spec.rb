require "spec_helper"

describe "routing to api" do
=begin
  it "should route /api/:id/:region/:size/:rotation/:file to api#index" do
    { :get => "/api/09064710/full/,120/0/native.png" }.should route_to(
      :controller => "api",
      :action => "index",
      :id => "09064710",
      :region => "full",
      :size => ",120",
      :rotation => "0",
      :file => "native" 
    )
  end

  it "should not reach api with wrong number of parameters" do
    { :get => "/api/09064710/full/,120/0/native.png/12345" }.should_not be_routable
    { :get => "/api/09064710/full/,120" }.should_not be_routable
    { :get => "/api/09064710/full" }.should_not be_routable
    { :get => "/api/09064710" }.should_not be_routable
  end
  it "should not expose api" do
    { :get => "/api" }.should_not be_routable
  end
=end
  it "should not expose private api controller methods" do
    { :get => "/api/render_404" }.should_not be_routable
    { :get => "/api/render_400" }.should_not be_routable
  end  
end
