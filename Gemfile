source 'https://rubygems.org'

gem 'rails', '3.2.19'

gem 'rmagick', :require => false
gem 'rsolr'
gem 'memcache-client'
gem 'pg'
gem 'omniauth-cas', '1.0.1'

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :test, :development do
  gem 'sqlite3'
  gem 'rspec-rails'
  gem 'debugger'
end

group :test do
  gem 'capybara'
  gem 'webmock'
end

group :development do
  gem 'brakeman'
  gem 'rails_best_practices'
end

# Deploy with Capistrano
gem 'capistrano'
