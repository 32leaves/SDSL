require 'opal'
require 'sinatra/base'

require '../../lib/NLSL'
require '../../lib/NLSE'
require '../../lib/NLSLParser'
require '../../lib/NLSLtoNLSE'
require '../../lib/target.ruby'


class App < Sinatra::Base

  get '/' do
    send_file 'public/index.html'
  end


  get '/compile/:type/:name' do
    type = params[:type].to_sym
    fn = {
        :geometry => '../../examples/circle.geom.nlsl',
        :color => '../../examples/gradient.color.nlsl'
    }[type]

    p = NLSLParser.new.parse(File.new(fn).readlines.join)
    n = NLSL::Compiler::Transformer.new(type).transform(p)
    r = NLSE::Target::Ruby::Transformer.new(params[:name]).transform(n)
    Opal.compile(r)
  end

end