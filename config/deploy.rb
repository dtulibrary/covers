# RVM bootstrap
# $:.unshift(File.expand_path('./lib', ENV['rvm_path']))

set :rvm_ruby_string, '1.9.3-p194'
set :rvm_type, :system

require 'rvm/capistrano'

# bundler bootstrap
require 'bundler/capistrano'

# server details
set :rails_env, ENV['RAILS_ENV']
default_run_options[:pty] = true
ssh_options[:forward_agent] = false
set :deploy_via, :remote_cache
set :user, "#{ENV['CAP_USER']}"
set :use_sudo, false

# repo details
set :scm, :git
set :scm_username, "#{ENV['CAP_USER']}"
set :repository, "#{ENV['SCM']}"
if variables.include?(:branch_name)
  set :branch, "#{branch_name}"
else
  set :branch, "master"
end  
set :git_enable_submodules, 1

set :deploy_to, "/var/www/#{ENV['HOST']}"
set :application, "#{ENV['HOST']}"
role :web, "#{ENV['HOST']}"                          # Your HTTP server, Apache/etc
role :app, "#{ENV['HOST']}"                          # This may be the same as your `Web` server
role :db,  "#{ENV['HOST']}", :primary => true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"
namespace :db do
  task :setup do
    template = File.read("config/deploy/database.yml.erb")
    config = ERB.new(template).result(binding)
    put config, "#{release_path}/config/database.yml"
  end
end
namespace :api do
  task :setup do
    template = File.read("config/deploy/api.yml.erb")
    config = ERB.new(template).result(binding)
    put config, "#{release_path}/config/api.yml"
  end
end
before "deploy:assets:precompile", "db:setup"
before "deploy:assets:precompile", "api:setup"
# tasks
namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

#after "deploy:finalize_update", "deploy:config:generate"
