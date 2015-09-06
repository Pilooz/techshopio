# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift(File.dirname(__FILE__))
require ::File.expand_path('../app', __FILE__)
require ::File.expand_path('../controller/sinatra_controller', __FILE__)

use Rack::Rewrite do
  rewrite %r{/.*/(app)/(.*)}, '/$1/$2'
  rewrite %r{/.*/(pictures)/(.*)}, '/$1/$2'
  rewrite %r{/.*/(css)/(.*)}, '/$1/$2'
end   

run SinatraApp
