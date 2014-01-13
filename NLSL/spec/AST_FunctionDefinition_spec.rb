require 'rspec'
require 'spec_helper'

describe 'AST Function Definition parser' do
  include NLSL::SpecHelper

  it 'should parse empty functions' do
    parse('void main() { }')
  end

  it 'should parse return types' do
    parse('int main() { }').content.first.return_type == 'int'
  end

  it 'should parse names' do
    parse('int main() { }').content.first.name == 'main'
  end

  it 'should parse function bodies' do
    body = parse('int main() { int x = 0; }').content.first.body
    body.should_not be_nil
    body.should be_a NLSL::FunctionBody
    body.statements.should_not be_nil
    body.statements.length == 1
  end

  it 'should parse functions with one argument' do
    p = parse("vec4 foo(vec4 x) { }")
    p.should_not be_nil

    args = p.content.first.arguments
    args.should_not be_nil
    args.should have(1).item
    args.first.name.should eq "x"
    args.first.type.should eq "vec4"
  end

  it 'should parse functions with more arguments' do
    p = parse("vec4 foo(vec4 x, float y) { }")
    p.should_not be_nil

    args = p.content.first.arguments
    args.should_not be_nil
    args.should have(2).items
    args.first.type.should eq "vec4"
    args.first.name.should eq "x"
    args.last.type.should eq "float"
    args.last.name.should eq "y"
  end

  ####
  # LEGACY specs
  ####
  it 'should parse the main function' do
    parse("void main() { }").should_not be_nil
  end

  it 'should parse functions with a body' do
    parse("void main() { float x = 42; }").should_not be_nil
    parse("void main() { float x = 42; vec2 y = vec2(x, 1) * 2; }").should_not be_nil
  end


  it 'should parse functions that return something' do
    parse("vec4 foo(vec4 x) { return vec4(1, 2, 3, 4); }").should_not be_nil
    parse("vec4 foo(vec4 x, float y) { return x * y; }").should_not be_nil
  end


end