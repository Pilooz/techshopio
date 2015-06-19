# coding: utf-8
require 'sinatra/reloader' if ENV['RACK_ENV'] == 'development'
require 'laclasse/helpers/authentication'
require 'laclasse/cross_app/sender'

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

  helpers Laclasse::Helpers::Authentication
  helpers Laclasse::Helpers::AppInfos

  # Routes nécessitant une authentification
  # rubocop:disable Style/BlockDelimiters
  ['/?', '/login'].each { |route|
    before APP_PATH + route do
      login! env['REQUEST_PATH'] unless logged?
    end
  }
  # rubocop:enable Style/BlockDelimiters

  get APP_PATH + '/' do
    if logged?
      erb "<h1>Connected !</h1>
          Test d'Api Grape :
          <a href='#{APP_PATH}/api/test'>Api simple</a>
          <pre>
            #{env['rack.session'][:current_user].to_html}
          </pre><hr>"
    else
      erb "<div class='jumbotron'>
            <h1>Public page</h1>
            <p class='lead'>This starter app is an example of Omniauth-cas
                and sinatra integration based on rack system.<br />
            Please try to connect with CAS sso...
            </p>
            </div>"
    end
  end

  get "#{APP_PATH}/status" do
    content_type :json
    app_status = app_infos

    app_status[:status] = 'OK'
    app_status[:reason] = 'L\'application fonctionne.'

    app_status.to_json
  end

  get APP_PATH + '/auth/:provider/callback' do
    init_session(request.env)
    home = env['rack.url_scheme'] + '://' + env['HTTP_HOST'] + APP_PATH + '/'
    redirect params[:url] if params[:url] != home
    redirect APP_PATH + '/'
  end

  get APP_PATH + '/auth/failure' do
    erb "<h1>L'authentification a échoué : </h1>
        <h3>message:<h3> <pre>#{params}</pre>"
  end

  get APP_PATH + '/login' do
    login! APP_PATH + '/'
  end

  get APP_PATH + '/logout' do
    logout! env['rack.url_scheme'] + '://' + env['HTTP_HOST'] + APP_PATH + '/'
  end
end
