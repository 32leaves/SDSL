require 'rspec'
require 'spec_helper'

describe 'AST Function Definition parser' do
  include NLSL::SpecHelper

  it 'should parse uniform definition names' do
    parse('uniform float foobar;').content.first.name.should eq 'foobar'
  end

  it 'should parse uniform definition types' do
    parse('uniform float foobar;').content.first.type.should eq 'float'
  end

  it 'should not require a uniform' do
    parse('void main() { }').should_not be_nil
  end

end