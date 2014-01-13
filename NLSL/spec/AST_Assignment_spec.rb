require 'rspec'
require 'spec_helper'

describe 'AST Assignment' do
  include NLSL::SpecHelper

  before do
    @a = parse('float bar = 1', 'assignment')
  end

  it 'should have a vartype' do
    @a.type == 'float'
  end

  it 'can not have a vartype' do
    parse('bar = 1', 'assignment').type.should be_nil
  end

  it 'should have a varname' do
    @a.name == 'bar'
  end

  it 'should have an expression' do
    @a.expression.should_not be_nil
  end

  it 'should allow unary prefix assignments' do
    p = parse('++foo', 'unary_assignment')
    p.name.should eq 'foo'
    p.operator.should eq '++'
    p.prefix?.should be true

    p = parse('--foo', 'unary_assignment')
    p.name.should eq 'foo'
    p.operator.should eq '--'
    p.prefix?.should be true
  end

  it 'should allow unary postfix assignments' do
    p = parse('foo++', 'unary_assignment')
    p.name.should eq 'foo'
    p.operator.should eq '++'
    p.prefix?.should be false

    p = parse('foo--', 'unary_assignment')
    p.name.should eq 'foo'
    p.operator.should eq '--'
    p.prefix?.should be false
  end

end