# encoding: utf-8

require 'bundler'
require_relative '../config/init'
Bundler.require( :default, ENV['RACK_ENV'].to_sym ) # require tout les gems définis dans Gemfile

namespace :server  do
  desc 'Starts puma server for TechShopIO'
  task :start do
    system "puma #{APP_ROOT}/config.ru"
  end
  desc 'Stops Puma server'
  task :stop do
    system "puma stop"
  end
  desc 'Restarts Puma server'
  task :restart do
    system "puma restart"
  end
end