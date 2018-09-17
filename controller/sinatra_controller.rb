# coding: utf-8
require 'sinatra/reloader' if ENV['RACK_ENV'] == 'development'
require 'socket'
require 'data_uri'
require 'csv'
require 'tilt/erb'
require 'date'
require 'json'
require 'pdfkit'

# Application Sinatra servant de base
class SinatraApp < Sinatra::Base
  configure do
    set :app_file, __FILE__
    set :port, APP_PORT
    set :root, APP_ROOT
    set :public_folder, proc { File.join(root, 'public') }
    set :inline_templates, true
    set :protection, true
    set :lock, true
    set :bind, '0.0.0.0' # allowing acces to the lan
    # set :environment, ENV['RACK_ENV']
    mime_type :csv, 'text/csv'
    mime_type :pdf, 'application/pdf'
  end

  configure :development do
    # register Sinatra::Reloader
    # also_reload "#{APP_ROOT}/lib/db.rb"
    # dont_reload '/path/to/other/file'
  end

  helpers do
    # Text Translation function
    def _t(s)
      # if TRANSLATE[s].nil?
      #   s = "@@-- #{s} --@@"
      #   return s
      # end
      s = TRANSLATE[s][APP_LANG] unless TRANSLATE[s].nil?
      s
    end

    # Help Translation function
    def _h(s)
      # if HELP[s].nil?
      #   s = "@@-- #{s} --@@"
      #   return s
      # end
      s = HELP[s][APP_LANG] unless HELP[s].nil?
      s
    end

    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      # TODO : display a beautiful error plz...
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ADMIN_LOGIN, ADMIN_PWD]
    end
   
    def get_csv_data(list, cols)
      list.each { |r|
        r.reject! { |k, _| !cols.include? k }
      }
      column_names = list.first.keys

      listcsv = CSV.generate({:col_sep => ";"}) { |csv|
        csv << column_names
        list.each { |x| csv << x.values }
      }  
      listcsv
    end

  end

  before do
    @nav_list = ''
    @nav_out = ''
    @nav_new = ''
    @nav_barcode = ''
    @nav_populate = ''
    @nav_tags = ''
    @nav_checkin = ''
    @nav_stats = ''
    @nav_settings = ''
    @code = params['code']
    @item = DB.read @code
    @publiclist = false
    @massive = params['massive'] # Contains tag id when massive checkout mode activated
    # Add login /pwd authentification for none public pages (all but ../catalog :) )
# TODO  : write a  test more ruby compliant !!!
    protected! unless env['REQUEST_URI'] == APP_PATH || env['REQUEST_URI'] == APP_PATH + '/' || env['REQUEST_URI'] == APP_PATH + '/catalog'
  end

  get APP_PATH + '/?' do
    unless @code.nil? || @code.empty?
      # See where we have to go now... don't exists => In, else Out
      if !DB.exists? @code
        # Item doesn't exist in inventory, add it.
        redirect to APP_PATH + "/new?code=#{@code}"
      else
        # Item exist, if it wasn't out, then checkout
        if !DB.checkout? @code 
            redirect to APP_PATH + "/out?code=#{@code}&massive=#{@massive}"
        else
          # If it is allready out, automatic checkin
          # redirect to APP_PATH + "/checkin?code=#{@code}"
          redirect to APP_PATH + "/item/checkin?code=#{@code}"
        end
      end
    end
    @ip = ""
    s = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
    unless s.nil?
      @ip = s.ip_address.to_s 
    end
    # @server_url = "http://" + ip + ":" + APP_PORT.to_s + APP_PATH + "/"
    erb :index
  end

  # Route for admin list of the TechShop
  get APP_PATH + '/list' do
    # Propose list of TechShop on index page
    @items = DB.select_all_items
    @tags = DB.select_all_tags
    @nav_list = 'active'
    @main_title = _t 'List'
    @placeholder =  _t 'type or scan reference'
    erb :list
  end

  # Route for the public version (without admin features) of techShop list
  get APP_PATH + '/catalog' do
    # Propose list of TechShop on index page
    @items = DB.select_all_items
    @nav_publiclist = 'active'
    @main_title = _t 'List'
    @placeholder =  _t 'type or scan reference'
    @publiclist = true
    erb :list
  end

  get APP_PATH + '/out' do
    # If Single checkout mode, propose "out" screen
    if @massive.nil? || @massive.empty?
      @main_title = _t 'Check-out stuff from Techshop'
      @nav_out = 'active'
      # Getting all affected tags for this item
      @assigned_tags = DB.select_tags_for_item @code
      # Getting all accessibles tags
      @available_tags = DB.select_available_tags_for_item @code # DB.select_all_tags
      erb :out 
    else # If massive checkout, proceed automatically and refresh on list
      DB.checkout @code, params['chkout_date'], params['chkin_date']
      DB.link_tag @code, @massive.to_i
      chk_in_out_dates_params = USE_CHECKINOUT_DATE == "Y" ? "&chkout_date=#{params['chkout_date']}&chkin_date=#{params['chkin_date']}" : ""
      redirect to APP_PATH + "/list?massive=#{@massive}" + chk_in_out_dates_params   
    end

  end

  get APP_PATH + '/new' do
    @main_title = _t 'Adding stuff in TechShop'
    @nav_new = 'active'
    @action = 'new'
    erb :new_modify
  end

  get APP_PATH + '/modify' do
    @main_title = _t 'Modifying stuff in TechShop'
    @nav_new = 'active'
    @action = 'modify'
    # Getting all affected tags for this item
    @assigned_tags = DB.select_tags_for_item @code
    erb :new_modify
  end

  get APP_PATH + '/checkin' do
    @main_title = _t 'Check-in stuff in TechShop'
    @nav_checkin = 'active'
    # Getting all affected tags for this item
    @assigned_tags = DB.select_tags_for_item @code
    erb :checkin
  end

  get APP_PATH + '/logout' do
    @auth = nil
    redirect to APP_PATH + "/"
  end

  get APP_PATH + '/delete' do
    DB.delete_item params['code']
    redirect to APP_PATH + "/list"
  end

  get APP_PATH + '/barcode?' do
    @main_title = _t 'Generate barecodes'
    @nav_barcode = 'active'
    # Reading last id from db
    lastid = 0
    lastid = DB.lastid 'items', 'code'
    if lastid =~ /[A-z]/ 
      # Extracting numerical part and alphabetical part
      @radical = lastid.tr('0-9', '')
      lastid = lastid.tr('A-z', '')
    end 
    @from = lastid.to_i + 1
    @to = @from + 100
    erb :barcode
  end

  get APP_PATH + '/tags' do
    @tags = DB.select_all_tags
    @main_title = _t 'Dealing with tags stuff'
    @nav_tags = 'active'
    erb :tags
  end

  get APP_PATH + '/populate' do
    @main_title = _t 'Populate TechShop massively'
    @nav_populate = 'active'
    erb :populate
  end

  # Route for checkout stats
  get APP_PATH + '/stats' do
    @tags = DB.select_all_tags
    @nav_stats = 'active'
    @main_title = _t 'Check-out statistics'
    erb :stats
  end

  get APP_PATH + '/settings' do
    @main_title = _t 'Settings'
    @nav_settings = 'active'
    erb :settings
  end

  # Receive csv data
  post APP_PATH + '/populate' do
    DB.add_serveral_items  JSON.parse params['jsondata'] unless params['jsondata'].nil?
    # Redirect to the Techshop's list
    redirect to APP_PATH + "/list"
  end

   # Create or modify item
  post APP_PATH + '/item/new_modify' do
    if params['code']
      begin
        if params['action'] == 'new'
          # TODO : Deals with Image Upload !!
          DB.add_item params['code'], params['name'], params['description'], params['image_link'], "N", "", ""
        else
          DB.update_item params['code'], params['name'], params['description'], params['image_link']
        end
      rescue Exception => e
        puts "#{e.message}"
        e.backtrace[0..10].each { |t| puts "#{t}"}
        {'result' => 'Error', "message" => e.message }.to_json
      end

    end
     redirect to APP_PATH + "/list"
  end

   # Checkout item
  post APP_PATH + '/item/checkout' do
    if params['code']
      DB.checkout params['code'], params['chkout_date'], params['chkin_date']
    end
    redirect to APP_PATH + "/list"
  end

  # Checkin item
  get APP_PATH + '/item/checkin' do
    if params['code']
      DB.unlink_item params['code']
      DB.checkin params['code']
    end
    if !@massive.nil? && !@massive.empty? 
      redirect to APP_PATH + "/list?massive=#{@massive}" 
    end
    redirect to APP_PATH + "/list" 
  end

  #
  # CRUD and Ajax Room service !
  #

  get APP_PATH + '/item/picture/path' do
    if params['code']
      @item[0]['image_link']
    end
  end

  # Posting thumbnail in Base64 mode.
  post APP_PATH + '/item/picture' do  
    if params['code'] && params['label'] && params['labelthumb'] && params['thumb'] && params['picture']
      begin
        uri = URI::Data.new params['thumb']
        # Writing thumbnail
        File.open("#{APP_ROOT}/public/pictures/#{params['labelthumb']}", 'wb') do |f|
          f.write uri.data 
        end
        # Writing picture
        File.open("#{APP_ROOT}/public/pictures/#{params['label']}", 'wb') do |f|
          f.write (params['picture'][:tempfile].read)
        end
        # Updating db.
        DB.update_item_image_link @code, params['label']
        {'result' => 'Ok'}.to_json
      rescue Exception => e
        puts "#{e.message}"
        e.backtrace[0..10].each { |t| puts "#{t}"}
        {'result' => 'Error', "message" => e.message }.to_json
      end
    end
  end

  # Receive tags data
  post APP_PATH + '/tag/add' do
    DB.add_tag params['tag'], params['color'], params['firstname'] , params['lastname'] , params['email']
    # Redirect to the tags' list
    redirect to APP_PATH + "/tags"
  end

  get APP_PATH + '/tag/delete' do
    DB.delete_tag params['id']
    # Redirect to the tags' list
    redirect to APP_PATH + "/tags"
  end

  # sending Tag infos
  get APP_PATH + '/tag/info/' do
    res = nil
    if params['id'] && params['expand'] == 'Y'
      res = DB.select_items_for_tag params['id']
    else
      res = DB.select_tag params['id']
    end
    res.to_json
  end

  # Extract data for a specific tag in pdf format
  get APP_PATH + '/tag/pdf/' do 
    if params['id']
       # add a file description in http header
      tag = DB.select_tag params['id']
      # attachment tag[0]['tag'] + '.pdf'

      list = DB.select_items_for_tag params['id']
      # doc = Pdf.new("<h1>This is my Pdf for tag :"+list[0]['tag']+"</h1>")
      # doc = Pdf.new("test")
      # kit = PDFKit.new("http://localhost:#{APP_PORT}#{APP_PATH}/tag/info/?id=" + params['id'])
      kit = PDFKit.new("<h1>This is my Pdf for tag :"+list[0]['tag']+"</h1>", :page_size => 'A4')
      # kit.stylesheets <<  __dir__('../public/css/bootstrap.css')
      pdf = kit.to_pdf

      content_type :pdf
      attachment list[0]['tag'] + '.pdf'
      pdf
    end
  end

  post APP_PATH + '/tag/add_contact' do

    if params['tagid']
      DB.add_contact_to_tag params['tagid'], params['firstname'] , params['lastname'] , params['email']
    end
    # Redirect to the tags' list
    redirect to APP_PATH + "/tags"
  end


  get APP_PATH + '/tags/list' do
    res = DB.select_all_tags
    res.to_json
  end

  # Linking Tag to item
  get APP_PATH + '/tags/add/' do
    if params['code'] && params['id']
      DB.link_tag params['code'], params['id']
    end
    {'result' => 'Ok'}.to_json
  end

  # Unlinking Tag from item
  get APP_PATH + '/tags/remove/' do
    if params['code'] && params['id']
      DB.unlink_tag_from_item params['code'], params['id']
    end
    {'result' => 'Ok'}.to_json
  end

  #--------------------------------------------------------------------------
  # CSV Controllers
  #--------------------------------------------------------------------------

  # Extract list at csv format
  get APP_PATH + '/list/csv' do 
    list = DB.select_all_items false
    content_type :csv
    attachment 'list.csv'
    get_csv_data list, ["code","name","description","image_link","checkout"]
  end

  # Extract data for a specific tag in csv format
  get APP_PATH + '/tag/csv/' do 
    content_type :csv
    if params['id']
      list = DB.select_items_for_tag params['id']
      tag = DB.select_tag params['id']
      # Taking first tag to give the name
      attachment tag[0]['tag'] + '.csv'
      get_csv_data list, ["code","name","description"]
    end
  end

  # Extract all tags data
  get APP_PATH + '/tags/csv' do 
    content_type :csv
    attachment 'tags.csv'
    get_csv_data DB.select_tags, ["id", "tag", "color", "firstname", "lastname", "email"]
  end

  # Extract all items_log
  get APP_PATH + '/stats/csv' do 
    content_type :csv
    attachment 'items_log.csv'
    get_csv_data DB.select_all_items_log, ["item_code", "tag_id", "move", "move_date"]
  end

  # Extract all tags_items
  get APP_PATH + '/tags_items/csv' do 
    content_type :csv
    attachment 'tags_items.csv'
    get_csv_data DB.select_all_tags_items, ["item_code", "tag_id"]
  end

  #--------------------------------------------------------------------------
  # dbsave Controller : Admin path to save database
  #--------------------------------------------------------------------------
  get APP_PATH + '/dbsavetocsv' do 

    def write_file(filename, data)
      puts "writing file #{filename}"
      File.open("#{APP_ROOT}/db/files/"+filename, 'w') { |file| file.write(data) }
      puts "done !"
    end

    puts '----------> Saving database to CSV files... <----------'
    puts "The target directory is #{APP_ROOT}/db/files/"
    puts 'get csv of items table...'
    items = get_csv_data DB.select_all_items(false), ["code","name","description","image_link","checkout", "chkout_date", "chkin_date"]
    write_file "items.csv", items

    puts 'get csv of tags table...'
    tags = get_csv_data DB.select_tags, ["id", "tag", "color", "firstname", "lastname", "email"]
    write_file "tags.csv", tags

    puts 'get csv of tags_items table...'
    tags_items = get_csv_data DB.select_all_tags_items, ["item_code", "tag_id"]
    write_file "tags_items.csv", tags_items

    puts 'get csv of items_log table...'
    items_log = get_csv_data DB.select_all_items_log, ["item_code", "tag_id", "move", "move_date"]
    write_file "items_log.csv", items_log

    puts '----------> Done ! Database exported to CSV <----------'
  end
 
  #--------------------------------------------------------------------------
  # dbrestore Controller : Admin path to restore database only it is empty.
  #--------------------------------------------------------------------------
  get APP_PATH + '/dbrestorefromcsv' do 
    db_path = "#{APP_ROOT}/db/files/"
    files = ['items', 'tags', 'tags_items']
    all_file_exist = true

    def is_int(str)
      # Check if a string should be an integer
      return !!(str =~ /^[-+]?[1-9]([0-9]*)?$/)
    end

    # Preparing data for DB insertions
    def prepareData(csv_filename)
      data = []
      puts "Converting '#{csv_filename}'  into json..."
      CSV.foreach("#{APP_ROOT}/db/files/#{csv_filename}", col_sep: ";" ) do |row|
        data.push row
      end
      data
    end


    puts '----------> Restoring database from CSV files... <----------'
    if DB.empty_DB?
      puts 'Verifying CSV file existance...'
      files.each { |f| 
        if !File.exists? db_path + f + ".csv"
          all_file_exist = false
          puts "ERROR ! The file '#{f}.csv' was not found !"
        end
      }
      
      if all_file_exist
        puts 'All required cvs files found ! DB Restore can start...'
        json_data = {}
        files.each { |f| 
          data = prepareData f + ".csv"
          puts "Calling DB.add_serveral_" + f 
          DB.send("add_serveral_#{f}", data)  
        }

        # Specific deal for Items_log table
        puts "Delete all data from items_log"
        DB.delete_items_log
        puts "Calling DB.add_serveral_items_log" 
        data = prepareData "items_log.csv"
        DB.add_serveral_items_log data
        
      else
        puts 'ERROR ! A csv file is missing, unable to restore database properly.'
      end

    else
      puts 'ERROR ! Database is not empty !'
    end
    puts '----------> Done ! Database imported from CSV <----------'
    # Redirect to the Techshop's list
    redirect to APP_PATH + "/list"
  end
end
