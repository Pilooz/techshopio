# coding: utf-8
require 'sinatra/reloader' if ENV['RACK_ENV'] == 'development'

# Application Sinatra servant de base
class SinatraApp < Sinatra::Base
  configure do
    set :app_file, __FILE__
    set :root, APP_ROOT
    set :public_folder, proc { File.join(root, 'public') }
    set :inline_templates, true
    set :protection, true
    set :lock, true
  end

  configure :development do
    register Sinatra::Reloader
    # also_reload '/path/to/some/file'
    # dont_reload '/path/to/other/file'
  end

  get APP_PATH + '/' do
      erb "<h4>Hello world !</h4>
          Test d'Api Grape :
          <a href='#{APP_PATH}/api/test'>Api simple</a>
          Test du status : <a href='#{APP_PATH}/api/status'>Status</a>
          <pre>
          </pre><hr>"
  end
end
