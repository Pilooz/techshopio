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
      if TRANSLATE[s].nil?
        s = "@@-- #{s} --@@"
        return s
      end
      s = TRANSLATE[s][APP_LANG] unless TRANSLATE[s].nil?
      s
    end
  end

  before do
    @nav_in = ''
    @nav_out = ''
    @nav_barcode = ''
    @code = params['code']
  end

  get APP_PATH + '/?' do
    # @code = params['code']
    unless @code.nil? || @code.empty?
      puts "========> #{DB.exists? @code}"
      # See where we have to go now... don't exists => In, else Out
      if !DB.exists? @code
        # Item doesn't exist in inventory, add it.
        redirect to APP_PATH + "/new?code=#{@code}"
      else
        # Item exist, if it was out, then check-in
        if DB.checkout?(@code)
          redirect to APP_PATH + "/in?code=#{@code}"
        else
          # If it is allready in, propose to modify it or checkout it
          redirect to APP_PATH + "/out?code=#{@code}"
        end
      end
    end
    @main_title = _t 'Welcome on TechShopIO !'
    @placeholder =  _t 'type or scan reference'
    erb :index
  end

  get APP_PATH + '/out?' do
    @main_title = _t 'Outing stuff'
    @nav_out = 'active'
    erb :out
  end

  get APP_PATH + '/in?' do
    @main_title = _t 'Check-in stuff in TechShop'
    @nav_in = 'active'
    erb :in
  end

  get APP_PATH + '/new?' do
    @main_title = _t 'Adding stuff in TechShop'
    @nav_new = 'active'
    erb :new
  end

  get APP_PATH + '/barcode?' do
    @main_title = _t 'Generate barecodes'
    @nav_barcode = 'active'
    erb :barcode
  end
end
