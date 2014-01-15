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
  TR_ASSIGNMENT = [ :transform_assignment, 'assignment' ]
  TR_UASSIGNMENT = [ :transform_unaryassignment, 'unary_assignment' ]

  def tr(s, conf = TR_ROOT, scope = NLSL::Compiler::ROOT_SCOPE.clone, &block)
    start, root = conf

    p = parse(s, root)
    raise "Parse failed: #{@p.failure_reason}" if p.nil?

    program = NLSE::Program.new(:root_scope => scope, :functions => NLSL::Compiler::BUILTIN_FUNCTIONS.clone)

    transformer = NLSL::Compiler::Transformer.new
    result = transformer.send(start, p, scope, program)

    yield result, transformer, scope, program if block_given?

    result
  end

end