def read_db_config(file, env)
  YAML.load_file(file)[env]
end

def get_settings
  get(File.join(shared_path, "config/database.yml"), "tmp/database.yml")
  stage_db_settings = read_db_config("tmp/database.yml", "production")
  prod_db_settings = read_db_config("tmp/database.yml", "arena_production")
  FileUtils.rm "tmp/database.yml"
  
  [stage_db_settings, prod_db_settings]
end

def timestamp
  Time.now.utc.strftime("%Y%m%d%H%M%S")
end

set :rails_env, :production
set :unicorn_binary, "/usr/local/bin/unicorn"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && #{try_sudo} #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill `cat #{unicorn_pid}`"
  end
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
  end
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
end
namespace :sets do
  task :sync_local do
    local_backup = File.expand_path("tmp/sets")
    remote_loc = File.join(shared_path, "sets")
    FileUtils.mkdir_p local_backup
    system "rsync -azv -e ssh --delete #{user}@#{application}:#{remote_loc} #{local_backup}"
  end
end

namespace :db do
  task :symlink, :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/sets #{release_path}/sets"
  end
  
  task :sync do
    stage_db_settings, prod_db_settings = get_settings
    run "mysqldump #{prod_db_settings["database"]} -h #{prod_db_settings["host"]} -u #{prod_db_settings["username"]} -p#{prod_db_settings["password"]} | mysql #{stage_db_settings["database"]} -u #{stage_db_settings["username"]} -p#{stage_db_settings["password"]} -h #{stage_db_settings["host"]}"
  end
  
  task :backup do
    stage_db_settings, prod_db_settings = get_settings
    backup_file = "#{shared_path}/backup_#{timestamp}.bz2"
    run "mysqldump #{prod_db_settings["database"]} -h #{prod_db_settings["host"]} -u #{prod_db_settings["username"]} -p#{prod_db_settings["password"]} | bzip2 > #{backup_file}"
    get backup_file, File.join("tmp", File.basename(backup_file))
    run "rm #{backup_file}"
  end
  
  task :sync_local do
    backup
    latest_backup = Dir["tmp/backup_*.bz2"].sort.last
    local_db_settings = read_db_config("config/database.yml", "development")
    system "bzcat #{latest_backup} | mysql #{local_db_settings["database"]} -u #{local_db_settings["username"]} -p #{local_db_settings["password"]}"
  end
end

namespace :log do
  task :tail do
    run "tail -f #{File.join(shared_path, "log/production.log")}"
  end
end

after "deploy:finalize_update", "db:symlink"
