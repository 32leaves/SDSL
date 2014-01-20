require 'bundler'
Bundler.require

map '/assets' do
  env = Opal::Environment.new
  env.append_path 'app'
  env.append_path '../../lib'
  run env
end

map '/vendor' do
  run Rack::Directory.new('public/vendor')
end

require './app'
run App.new
