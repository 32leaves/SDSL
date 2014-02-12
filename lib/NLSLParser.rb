
require 'treetop'

basepath = File.expand_path(File.dirname(__FILE__))
require File.join(basepath, 'NLSL.rb')
if File.exists? File.join(basepath, 'NLSLParserGen.rb')
  require File.join(basepath, 'NLSLParserGen.rb')
else
  Treetop.load(File.join(basepath, 'NLSLParser.treetop'))
end

require File.join(basepath, 'class.treetopHelper.rb')
