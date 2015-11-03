require 'bundler'
# require 'rake/clean'

# include Rake::DSL
# Bundler::GemHelper.install_tasks

# begin; require 'rubygems'; rescue LoadError; end

require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'

Dir.glob(File.expand_path('../tasks/*.rake', __FILE__)).each do |f|
  import(f)
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--require spec_helper --color'
end

task default: :spec
