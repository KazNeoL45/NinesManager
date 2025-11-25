max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

workers ENV.fetch("WEB_CONCURRENCY") { 4 }

preload_app!

rackup      DefaultRackup
environment ENV.fetch("RAILS_ENV") { "production" }

app_dir = ENV.fetch("APP_DIR") { "/var/www/ninesmanager/current" }
shared_dir = ENV.fetch("SHARED_DIR") { "/var/www/ninesmanager/shared" }

bind "unix://#{shared_dir}/tmp/sockets/puma.sock"

pidfile "#{shared_dir}/tmp/pids/puma.pid"
state_path "#{shared_dir}/tmp/pids/puma.state"

stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

worker_timeout 30

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

plugin :tmp_restart
