namespace :server do
  desc 'Starts thin server'
  task :start do
    system("thin -C #{APP_ROOT}/config/thin.yml start")
  end
  desc 'Stops thin servers'
  task :stop do
    system("thin -C #{APP_ROOT}/config/thin.yml stop")
  end
  desc 'Restarts thin servers'
  task :restart do
    system("thin -C #{APP_ROOT}/config/thin.yml restart --onebyone")
  end
end
