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

    # Help Translation function
    def _h(s)
      if HELP[s].nil?
        s = "@@-- #{s} --@@"
        return s
      end
      s = HELP[s][APP_LANG] unless HELP[s].nil?
      s
    end
  end

  before do
    @nav_in = ''
    @nav_out = ''
    @nav_new = ''
    @nav_barcode = ''
    @nav_populate = ''
    @nav_tags = ''
    @code = params['code']
    @item = DB.read @code
  end

  get APP_PATH + '/?' do
    unless @code.nil? || @code.empty?
      # See where we have to go now... don't exists => In, else Out
      if !DB.exists? @code
        # Item doesn't exist in inventory, add it.
        redirect to APP_PATH + "/new?code=#{@code}"
      else
        # Item exist, if it was out, then check-in
        if !DB.checkout? @code
          redirect to APP_PATH + "/in?code=#{@code}"
        else
          # If it is allready in, propose to modify it or checkout it
          redirect to APP_PATH + "/out?code=#{@code}"
        end
      end
    end
    # Propose list of TechShop on index page
    @items = DB.select_all_items
    @main_title = _t 'Welcome on TechShopIO !'
    @placeholder =  _t 'type or scan reference'
    erb :index
  end

  get APP_PATH + '/out?' do
    @main_title = _t 'Check-out stuff from Techshop'
    @nav_out = 'active'
    # Getting all accessibles tags
    @tags = DB.select_all_tags
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
    erb :new_modify
  end

  get APP_PATH + '/modify?' do
    @main_title = _t 'Modifying stuff in TechShop'
    @nav_new = 'active'
    erb :new_modify
  end

  get APP_PATH + '/barcode?' do
    @main_title = _t 'Generate barecodes'
    @nav_barcode = 'active'
    # Reading last id from db
    lastid = DB.lastid 'items'
    if lastid =~ /[A-z]/ 
      # Extracting numerical part and alphabetical part
      @radical = lastid.tr('0-9', '')
      lastid = lastid.tr('A-z', '')
    end 
    @from = lastid.to_i + 1
    @to = @from + 100
    erb :barcode
  end

  get APP_PATH + '/populate' do
    @main_title = _t 'Populate TechShop massively'
    @nav_populate = 'active'
    erb :populate
  end

  # Receive csv data
  post APP_PATH + '/populate' do
    # TODO : See how to get barcode, if code are in csv file, perhaps will we have to produce these codes ?
    DB.add_serveral_items  JSON.parse params['jsondata'] unless params['jsondata'].nil?
    # Redirect to the Techshop's list
    redirect to APP_PATH + "/"
  end

  get APP_PATH + '/tags' do
    @tags = DB.select_all_tags
    @main_title = _t 'Dealing with tags stuff'
    @nav_tags = 'active'
    erb :tags
  end

  # Receive tags data
  post APP_PATH + '/tags' do
    DB.add_tag  params['tag'], params['color']
    # Redirect to the tags' list
    redirect to APP_PATH + "/tags"
  end

  # Linking Tag to item
  get APP_PATH + '/tags/add/' do
    "Ok Man ! #{params['id']}"
  end

  # Unlinking Tag from item
  get APP_PATH + '/tags/remove/' do
    "Ok Man ! #{params['id']}"
  end

end
