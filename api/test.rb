# Classe Grape de test
class TestApi < Grape::API
  format :json
  rescue_from :all

  get '/' do
    { message: 'Hello Word !' }
  end
end
