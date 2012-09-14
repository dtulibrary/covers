class User < ActiveRecord::Base
  #set_primary_key :api_key
  self.primary_key = 'api_key'
  attr_accessible :api_key,:sn,:ln,:default_height,:default_width,:on_missing_image,:on_missing_title
end
