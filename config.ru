# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift(File.dirname(__FILE__))
require ::File.expand_path('../app', __FILE__)
require ::File.expand_path('../controller/sinatra_controller', __FILE__)

use Rack::Rewrite do
  rewrite %r{/.*/(app)/(.*)}, '/$1/$2'
end

require 'laclasse/helpers/rack'
Laclasse::Helpers::Rack.configure_rake self

use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = APP_PATH + '/auth'
  end
  provider :cas,  CASAUTH::CONFIG
end

map APP_PATH + '/api' do
  run Api
end

run SinatraApp
