# Minimal sample configuration file for Unicorn (not Rack) when used
# with daemonization (unicorn -D) started in your working directory.
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
# See also http://unicorn.bogomips.org/examples/unicorn.conf.rb for
# a more verbose configuration using more features.

working_directory "/home/spoj0/current" # available in 0.94.0+

listen 80 # by default Unicorn listens on port 8080
worker_processes 4 # this should be >= nr_cpus
pid "/home/spoj0/shared/pids/unicorn.pid"
stderr_path "/home/spoj0/shared/log/unicorn.log"
stdout_path "/home/spoj0/shared/log/unicorn.log"

