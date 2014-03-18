require 'opal'
require 'sinatra/base'
require 'json'

require '../../lib/NLSL'
require '../../lib/NLSE'
require '../../lib/NLSLParser'
require '../../lib/NLSLtoNLSE'
require '../../lib/target.ruby'


class App < Sinatra::Base

  get '/' do
    send_file 'public/index.html'
  end

  post '/compile/:type/:name' do
    request.body.rewind
    payload = JSON.parse request.body.read

    type = params[:type].to_sym
    code = payload["code"]

    parser = NLSLParser.new
    parsed = parser.parse code
    if parsed.nil?
      status 420
      body({
        :error => "parser",
        :reason => parser.failure_reason,
        :where => {
            :line => parser.failure_line,
            :column => parser.failure_column,
            :offset => parser.failure_index
        }
      }.to_json)
    else
      begin
        nlse = NLSL::Compiler::Transformer.new(type).transform(parsed)
        ruby = NLSE::Target::Ruby::Transformer.new(params[:name]).transform(nlse)
        #File.open("debug.yaml", "w") {|f| f.puts nlse.to_yaml }
        #File.open("debug.rb", "w") {|f| f.puts ruby }

        status 200
        body Opal.compile(ruby)
      rescue NLSL::Compiler::CompilerError => e
        status 420
        body({
            :error => "compiler",
            :reason => e.message,
            :where => {
                :line => e.line,
                :offset => e.context.interval.begin
            }
        }.to_json)
      end
    end
  end

end