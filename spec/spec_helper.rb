require 'rubygems'
require 'rspec'
require 'rack/test'
require 'rack/lint'
require 'rack/mock'
# require 'sequel' # uncomment if needed
require 'logger'
require 'simplecov'

# Module pour tester les Api
module RSpecMixin
  include Rack::Test::Methods
  def app
    Api
  end
end

# configuration pour mocker la session
RSpec.configure do |config|
  # config.around(:each) do |test|
  #   Sequel.transaction([DB], rollback: :always) { test.run }
  # end
  config.include RSpecMixin
  config.mock_with :rspec
  config.expect_with :rspec

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end

require File.expand_path '../../app.rb', __FILE__
