require 'rspec'
require 'spec_helper'

describe 'AST If parser' do
  include NLSL::SpecHelper

  it 'should parse not an empty if block' do
    parse('if(foo == 42) { }', 'if').should be_nil
  end

  it 'should parse an else block' do
    p = parse('if(foo == 42) { int x = 42; } else { int y = 42; }', 'if')
    p.should_not be_nil
    p.condition.should_not be_nil
    p.condition.should be_a NLSL::OperationalExpression
    p.condition.operator.should eq "=="
    p.else_body.should_not be_nil
  end

  it 'should parse multiple statements in a block' do
    p = parse('if(foo == 42) { int x = 42; x = 42; }', 'if')
    p.should_not be_nil

    p.then_body.should have(2).items
  end

end