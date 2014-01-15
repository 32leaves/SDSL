require 'rspec'

describe 'NLSE Assignment' do
  include NLSE::SpecHelper

  it 'should register new variables and check the type' do
    tr('int foo = 42', NLSE::SpecHelper::TR_ASSIGNMENT) do |result, transformer, scope, program|
      result.name.should be :foo
      result.value.type.should be :int
      result.value.value.should eq 42

      scope[:foo].should_not be_nil
      scope.include?(:foo).should be true
    end

    expect { tr('int foo = 42.0', NLSE::SpecHelper::TR_ASSIGNMENT) }.to raise_error { |e|
      e.should be_a(NLSL::Compiler::CompilerError)
      e.message.downcase.should include "type mismatch"
    }
  end

  it 'should check if a variable exists' do
    expect { tr('foo = 42', NLSE::SpecHelper::TR_ASSIGNMENT) }.to raise_error(NLSL::Compiler::CompilerError)
  end

  it 'should check if a variable exists for unary assignments' do
    expect { tr('foo++', NLSE::SpecHelper::TR_UASSIGNMENT) }.to raise_error(NLSL::Compiler::CompilerError)
  end

  it 'should check if a unary assignment is available for the variable type' do
    expect {
      tr("""void bar() {
        vec2 foo = vec2(0.0, 0.0);
        foo++;
      }""", NLSE::SpecHelper::TR_FUNCDEF)
    }.to raise_error {|e|
      e.should be_a(NLSL::Compiler::CompilerError)
      e.message.should include "Unary assignments only exist for scalar types"
    }
  end

  it 'should resolve unary assignments' do
    scope = NLSL::Compiler::ROOT_SCOPE.clone
    scope.register_variable(:foo, :int)
    r = tr('foo++', NLSE::SpecHelper::TR_UASSIGNMENT, scope)
    r.should be_a NLSE::VariableAssignment
    r.name.should be :foo
    r.value.should be_a NLSE::ScalarAddScalar
    r.value.a.should be_a NLSE::Value
    r.value.a.value.should be :foo
    r.value.b.should be_a NLSE::Value
    r.value.b.value.should eq 1
  end

end