require 'pry'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/NLSLParser.rb'))

module NLSL::SpecHelper

  def initialize
    @p = NLSLParser.new
  end

  def parse(s, root = 'program')
    @p.parse(s, :root => root)
  end

end