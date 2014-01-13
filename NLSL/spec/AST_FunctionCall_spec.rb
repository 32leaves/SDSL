require 'rspec'
require 'spec_helper'

describe 'AST Function call parser' do
  include NLSL::SpecHelper

  it 'should parse the function name' do
    p = parse('foo()', 'funccall')
    p.should_not be_nil
    p.name.should eq "foo"
  end

  it 'should parse function arguments' do
    p = parse('foo(1, 2, 3)', 'funccall')
    p.should_not be_nil
    p.arguments.should have(3).items
    3.times {|i| p.arguments[i].should be_a NLSL::Expression }
  end

  it 'should parse nested function calls' do
    p = parse('foo(vec3(1, 2, 3))', 'funccall')
    p.should_not be_nil
    p.arguments.should have(1).item

    n = p.arguments.first.content.first
    n.should be_a NLSL::FunctionCall
    3.times {|i| n.arguments[i].should be_a NLSL::Expression }
  end

end