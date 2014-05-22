ImageDeliveryService::Application.routes.draw do
  get "user/index"

  match '/login',                   :to => 'users/sessions#new',       :as => 'new_user_session'
  match '/auth/:provider/callback', :to => 'users/sessions#create',    :as => 'create_user_session'

  get "/" => "api#wiki"
  get "api" => "api#wiki"
  get "api/:api_key" => "api#wiki"

  # The priority is based upon order of creation:
  # first created -> highest priority.
  get 'api/:api_key/:id/:region/:size/:rotation/:file' => 'api#index',:constraints=>{:rotation => /[^\/]+/},:as=>:api
  get 'api/:api_key/:id/info' => 'api#info',:constraints => {:format => /(xml|json)/}, :as => :info
  get 'api/:api_key/:id/:file' => 'api#index', :as => :api

  match 'user' => 'user#index', :as => :user
  match 'user/cache_reset' => 'user#cache_reset'
  match 'user/new' => 'user#new'
  match 'user/create' => 'user#create'
  match 'user/show' => 'user#show'
  match 'user/edit' => 'user#edit'
  match 'user/update' => 'user#update'
  match 'user/delete' => 'user#delete'

  match "*path" => 'api#render_error'
end
