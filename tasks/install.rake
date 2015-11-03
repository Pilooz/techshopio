#
# Rakefile
#
APP_ROOT_RAKE = File.expand_path(File.join(File.dirname(__FILE__), '..'))

task default: [:install]

desc 'Installing application'
task :install do
  # Adding config files from sample if not exist.
  puts "copying options.sample..."
  FileUtils.cp File.join(APP_ROOT_RAKE, 'config', 'options.sample'), File.join(APP_ROOT_RAKE, 'config', 'options.rb') unless File.exist? File.join(APP_ROOT_RAKE, 'config', 'options.rb')

  require_relative '../config/options'

  # Creating applcation directoies.
  ['db', 'db/files', 'public/pictures'].each { |d|
    puts "creating directory '#{d}'..."
    FileUtils.mkdir File.join(APP_ROOT_RAKE, d) unless File.exist? File.join(APP_ROOT_RAKE, d)
  }  
end
