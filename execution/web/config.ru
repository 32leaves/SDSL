require 'bundler'
Bundler.require

require 'opal/sprockets'

map '/assets' do
  env = Opal::Environment.new
  env.append_path 'app'
  env.append_path '../../lib'
  run env
end

map '/vendor' do
  run Rack::Directory.new('public/vendor')
end

require 'sass/plugin/rack'
Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack
map '/css' do
  run Rack::Directory.new('public/stylesheets')
end

require './app'
run App.new
