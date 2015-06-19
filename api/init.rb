require 'laclasse/helpers/authentication'
require 'laclasse/cross_app/sender'

puts 'loading api/testApi'
require __dir__('test')

# Point d'entrée des APi du suivi
class Api < Grape::API
  format :json
  rescue_from :all

  helpers Laclasse::Helpers::Authentication

  before do
    error!( '401 Unauthorized', 401 ) unless logged?
  end

  # Montage des toutes les api REST Grape
  resource(:test) { mount TestApi }

  add_swagger_documentation
end
