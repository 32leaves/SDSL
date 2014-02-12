require 'pry'
require 'treetop'
require './lib/NLSL.rb'
require './lib/NLSE.rb'
require './lib/NLSLtoNLSE.rb'
require './lib/class.treetopHelper.rb'
require './lib/target.ruby.rb'
require './lib/target.c.rb'

Treetop.load('lib/NLSLParser')

def parse(s, root = 'program')
  NLSLParser.new.parse(s, :root => root)
end

def p2xml(s, out = '/tmp/ast.xml')
  parser = NLSLParser.new
  r = parser.parse(s)
  throw parser.failure_reason if r.nil?

  File.open(out, "w") {|f| f.puts r.to_xml }
  r
end

gradient = p2xml(File.new('examples/gradient.color.nlsl').readlines.join, '/tmp/ast_gradient.xml')
circle = p2xml(File.new('examples/circle.geom.nlsl').readlines.join, '/tmp/ast_circle.xml')

g_se = NLSL::Compiler::Transformer.new(:color).transform(gradient)
g_cl = NLSL::Compiler::Transformer.new(:geometry).transform(circle)

begin
  rb_se = NLSE::Target::Ruby::Transformer.new.transform g_se
rescue ArgumentErrorcl => e
  puts e
end
begin
  rb_cl = NLSE::Target::Ruby::Transformer.new.transform g_cl
rescue ArgumentError => e
  puts e
end

resolution = NLSE::Target::Ruby::Runtime::Vec3.new(100, 100, 100)
cl = NLSE::Target::Ruby::GeometryShader.new(g_cl).execute(0, resolution, 16, 1)
se = NLSE::Target::Ruby::ColorShader.new(g_se).bind_uniform(:bluetone, 0.7).execute(0, resolution, cl)

puts NLSE::Target::C::Transformer.new.transform(g_cl)

pry