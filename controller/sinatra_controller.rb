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

  helpers do
    # Text Translation function
    def _t(s)
      if !TRANSLATE[s].nil?
        s = TRANSLATE[s][APP_LANG]
      end
      s
    end
  end

  before do
    @nav_list = ""
    @nav_in = ""
    @nav_out = ""
  end

  get APP_PATH + '/?' do
    @main_title = _t 'Welcome on TechShopIO !'
    @nav_list = 'active'
    @placeholder =  _t 'type or scan reference'
    erb :index
  end

  get APP_PATH + '/out' do
    @main_title = _t 'Outing stuff'
    @nav_out = 'active'
    erb :out
  end

  get APP_PATH + '/in' do
    @main_title = _t 'Bringing back stuff in TechShop'
    @nav_in = 'active'
    erb :in
  end

end
