require 'rspec'
require 'spec_helper'

describe 'AST For parser' do
  include NLSL::SpecHelper

  it 'should parse not an empty for loop block' do
    parse('for(int i = 0; i < 10; i++) { }', 'for').should be_nil
  end

  it 'should parse the loop body' do
    p = parse('for(int i = 0; i < 42; i++) { foo = 0; }', 'for')
    p.should_not be_nil
    p.body.should_not be_nil
  end

  it 'should parse the initialization correctly' do
    p = parse('for(int i = 0; i < 42; i++) { foo = 0; }', 'for')
    p.should_not be_nil

    p.initialization.should_not be_nil
    p.initialization.should be_a NLSL::Assignment
    p.initialization.name.should eq "i"
    p.initialization.type.should eq "int"
    p.initialization.expression.should be_a NLSL::Expression
    p.initialization.expression.content.first.should be_a NLSL::NumberLiteral
    p.initialization.expression.content.first.value.should eq 0
  end

  it 'should parse the condition correctly' do
    p = parse('for(int i = 0; i < 42; i++) { foo = 0; }', 'for')
    p.should_not be_nil

    p.condition.should be_a NLSL::OperationalExpression
    p.condition.operator.should eq "<"
    p.condition.factors.should have(2).items
    p.condition.factors.first.should be_a NLSL::VariableRef
    p.condition.factors.first.value.should eq "i"
    p.condition.factors.last.should be_a NLSL::NumberLiteral
    p.condition.factors.last.value.should eq 42
  end

  it 'should support unary iteration assignments' do
    p = parse('for(int i = 0; i < 42; i++) { foo = 0; }', 'for')
    p.should_not be_nil

    p.iterator.should be_a NLSL::UnaryAssignment
    p.iterator.name.should eq "i"
    p.iterator.operator.should eq "++"
  end

  it 'should support iteration assignments' do
    p = parse('for(int i = 0; i < 42; i = foo(y)) { foo = 0; }', 'for')
    p.should_not be_nil

    p.iterator.should be_a NLSL::Assignment
    p.iterator.name.should eq "i"
    p.iterator.expression.content.first.should be_a NLSL::FunctionCall
  end

end