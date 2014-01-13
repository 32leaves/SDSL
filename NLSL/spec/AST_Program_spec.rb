require 'rspec'
require 'spec_helper'

describe 'AST Program paser' do
  include NLSL::SpecHelper


  it 'should parse comments' do
    p = parse('// foo bar')
    p.should_not be_nil
    p.content.first.should_not be_nil

    p.content.first.value == '// foo bar'
  end

  it 'should parse functions' do
    p = parse('void main() { }')
    p.should_not be_nil
    p.content.first.should_not be_nil

    p.content.first.should be_a NLSL::FunctionDefinition
  end

  it 'should parse whitespace' do
    parse(' ').should_not be_nil
  end

end