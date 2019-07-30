# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "rails"

set :deploy_via,              :remote_cache
set :deploy_to,               '/var/www/app_name'
set :assets_roles,            :app
set :migration_role,          :app

# Sidekiq setting

set :sidekiq_roles,            :app
set :sidekiq_config,           "#{current_path}/config/sidekiq.yml"

# Puma settings see:
# https://github.com/seuros/capistrano-puma
set :puma_threads,            [4, 16]
set :puma_workers,            0
set :puma_bind,               "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,              "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,                "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log,         "#{release_path}/log/puma.error.log"
set :puma_error_log,          "#{release_path}/log/puma.access.log"
set :puma_preload_app,        true
set :puma_worker_timeout,     nil
set :puma_init_active_record, true # Change to false when not using ActiveRecord
set :puma_env,                fetch(:rack_env, fetch(:rails_env, 'staging'))

## Linked Files & Directories (Default None)
set :linked_dirs,  %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system storage}
set :linked_files, %w{config/master.key config/database.yml}

# Custom tasks, see task description
namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end
  before :start, :make_dirs
end

#namespace :whenever do
#  desc 'Create & Update Whenever Cronjob'
#  task :update_crontab do 
#    on roles(:app) do
#      execute "cd #{release_path} && bundle exec whenever --clear-crontab #{fetch(:application)}"
#      whenever_cmd = "whenever --update-crontab #{fetch(:application)} --set environment=#{fetch(:rails_env, fetch(:stage, "production"))}"
#      execute "cd #{release_path} && bundle exec #{whenever_cmd}"
#    end
#  end
#  
#  after "deploy:updated",  "whenever:update_crontab"
#  after "deploy:reverted", "whenever:update_crontab"
# end

namespace :deploy do
  desc 'Make sure local git is in sync with remote.'
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/#{fetch(:branch)}`
        puts "WARNING: HEAD is not the same as origin/#{fetch(:branch)}"
        puts 'Run `git push` to sync changes.'
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end
  
  #desc 'Restart sidekiq systemd service'
  #task :restart_sidekiq do
  #  on roles(:app) do
  #    execute :sudo, :systemctl, :restart, :sidekiq
  #  end
  #end

  #desc 'Runs rake db:seed'
  #task :seed => [:set_rails_env] do
  #  on primary fetch(:migration_role) do
  #    within release_path do
  #      with rails_env: fetch(:rails_env) do
  #        execute :rake, "db:seed"
  #      end
  #    end
  #  end
  #end

  before :starting,     :check_revision
  #before :starting,     :backup_db
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  #after  :finishing,    :restart_sidekiq
end


# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
