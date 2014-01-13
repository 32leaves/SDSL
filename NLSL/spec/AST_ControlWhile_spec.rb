require 'rspec'
require 'spec_helper'

describe 'AST While parser' do
  include NLSL::SpecHelper

  it 'should parse not an empty while loop block' do
    parse('while(i > 42) { }', 'while').should be_nil
  end

  it 'should parse the condition' do
    p = parse('while(i > 42) { foo = 0; }', 'while')
    p.should_not be_nil

    p.condition.should be_a NLSL::OperationalExpression
    p.condition.operator.should eq ">"
    p.condition.factors.should have(2).items
    p.condition.factors.first.should be_a NLSL::VariableRef
    p.condition.factors.first.value.should eq "i"
    p.condition.factors.last.should be_a NLSL::NumberLiteral
    p.condition.factors.last.value.should eq 42
  end

  it 'should parse the loop body' do
    p = parse('while(i > 42) { foo = 0; }', 'while')
    p.should_not be_nil
    p.body.should_not be_nil
  end

end