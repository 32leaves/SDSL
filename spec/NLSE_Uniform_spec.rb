require 'rspec'

describe 'NLSE Uniforms' do
  include NLSE::SpecHelper

  it 'should register uniforms in root scope' do
    tr('uniform float foo;', NLSE::SpecHelper::TR_ROOT) do |result, transformer, scope, program|
      result.uniforms.should have_at_least(1).item

      result.root_scope.include?(:foo).should be true
      result.root_scope[:foo].should be :float
    end
  end

  it 'should compile uniforms' do
    tr('uniform float foo;', NLSE::SpecHelper::TR_ROOT) do |result, transformer, scope, program|
      result.uniforms.should have_at_least(1).item

      result.uniforms[:foo].should_not be_nil
      result.uniforms[:foo].name.should be :foo
      result.uniforms[:foo].type.should be :float
    end
  end

  it 'should find used/unused uniforms' do
    tr('uniform float foo;', NLSE::SpecHelper::TR_ROOT) do |result, transformer, scope, program|
      result.uniforms.should have_at_least(1).item

      result.used_uniforms.should have_at_most(result.uniforms.values.length - 1).items
      result.used_uniforms.any? {|e| e.name == :foo }.should be false
    end
  end

end