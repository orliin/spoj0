DEPLOY_STAGE = ENV['STAGE'] || "production"

load File.join(File.dirname(__FILE__), "deploys", DEPLOY_STAGE)
load File.join(File.dirname(__FILE__), "deploys/recipies")

set :repository, "git://github.com/orliin/spoj0.git"
set :user, "spoj0"
set :home_path, "/home/spoj0"
set :deploy_to, home_path
set :deploy_via, :remote_cache
set :port, 9122
set :use_sudo, false
set :scm, :git

role :web, application                          # Your HTTP server, Apache/etc
role :app, application                          # This may be the same as your `Web` server
role :db,  application, :primary => true # This is where Rails migrations will run
