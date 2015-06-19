# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift(File.dirname(__FILE__))
require ::File.expand_path('../app', __FILE__)
require ::File.expand_path('../controller/sinatra_controller', __FILE__)

use Rack::Rewrite do
  rewrite %r{/.*/(app)/(.*)}, '/$1/$2'
end   

map APP_PATH + '/api' do
  run Api
end

run SinatraApp
