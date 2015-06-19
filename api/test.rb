# Classe Grape de test
class TestApi < Grape::API
  format :json
  rescue_from :all

  get '/' do
    { message: 'Hello Word !' }
  end

  get '/status' do
    { status: 'OK', reason: "L'application fonctionne ! " }
  end
end
