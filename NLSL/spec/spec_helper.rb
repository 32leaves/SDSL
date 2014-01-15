require 'pry'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/NLSLParser.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/NLSE.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/NLSLtoNLSE.rb'))

module NLSL::SpecHelper

  def initialize
    @p = NLSLParser.new
  end

  def parse(s, root = 'program')
    @p.parse(s, :root => root)
  end

end

module NLSE::SpecHelper
  include NLSL::SpecHelper

  TR_ROOT = [ :transform, 'program' ]
  TR_FUNCDEF = [ :transform_function, 'functiondef' ]
  TR_UNIFORMDEF = [ :transform_uniform, 'uniformdef' ]
  TR_ASSIGNMENT = [ :transform_assignment, 'assignment' ]
  TR_UASSIGNMENT = [ :transform_unaryassignment, 'unary_assignment' ]

  def tr(s, conf = TR_ROOT, program = nil, scope = nil, &block)
    throw "program is not an NLSE::Program" unless program.nil? or program.is_a? NLSE::Program
    start, root = conf

    p = parse(s, root)
    raise "Parse failed: #{@p.failure_reason}" if p.nil?

    program ||= NLSE::Program.new(NLSL::Compiler::BUILTIN_FUNCTIONS, [])
    scope ||= program.root_scope

    transformer = NLSL::Compiler::Transformer.new(:geometry)
    result = transformer.send(start, p, scope, program)

    yield result, transformer, scope, program if block_given?

    result
  end

end