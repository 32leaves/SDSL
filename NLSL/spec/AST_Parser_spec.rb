require 'rspec'
require 'spec_helper'

describe 'NLSL primitives' do
  include NLSL::SpecHelper

  it 'should parse float' do
    parse("float foo = 42;", 'statement').should_not be_nil
  end

  it 'should parse vec2' do
    parse("vec2 foo = vec2(1, 2);", 'statement').should_not be_nil
  end

  it 'should parse vec3' do
    parse("vec3 foo = vec3(1, 2, 3);", 'statement').should_not be_nil
    parse("vec3 foo = vec3(bar, 3);", 'statement').should_not be_nil
  end

  it 'should parse vec4' do
    parse("vec4 foo = vec4(1, 2, 3, 4);", 'statement').should_not be_nil
    parse("vec4 foo = vec4(bar, 3, 4);", 'statement').should_not be_nil
    parse("vec4 foo = vec4(bar, 4);", 'statement').should_not be_nil
  end

  it 'should parse function calls' do
    parse("vec4 foo = xyz(bar, 4);", 'statement').should_not be_nil
    parse("foo(bar)", 'statement').should be_nil
  end

  it 'should parse vector components' do
    parse("foo.x", 'expression').should_not be_nil
    parse("foo.y", 'expression').should_not be_nil
    parse("foo.z", 'expression').should_not be_nil
    parse("foo.w", 'expression').should_not be_nil
    parse("foo.xy", 'expression').should_not be_nil
    parse("foo.xyz", 'expression').should_not be_nil
  end
  
  it 'should parse assignments' do
    parse("float bar = 1", 'assignment').should_not be_nil
    parse("bar = 1", 'assignment').should_not be_nil
  end

end