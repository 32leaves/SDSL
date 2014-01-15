
require 'treetop'

basepath = File.expand_path(File.dirname(__FILE__))
require File.join(basepath, 'NLSL.rb')
#require File.join(basepath, 'NLSLParserGen.rb')
require File.join(basepath, 'class.treetopHelper.rb')

Treetop.load(File.join(basepath, 'NLSLParser.treetop'))