puts 'loading api/testApi'
require __dir__('test')

# Point d'entrée des APi du suivi
class Api < Grape::API
  format :json
  rescue_from :all

  # Montage des toutes les api REST Grape
  resource(:test) { mount TestApi }

  add_swagger_documentation
end
