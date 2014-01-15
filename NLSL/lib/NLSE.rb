require 'constructor'

#
# NLSE = NanoLite Shader Execution representation
#
# This module contains an intermediary representation of the shader code. Types have been resolved (typically by NLSL Compiler)
# so all expressions are typed. Code represented as NLSE is supposed to be transformed to the respective
# runtime environments using target transformers.
#
module NLSE

  class Comment
    constructor :value, :accessors => true
  end

  class Value
    constructor :type, :value, :ref, :accessors => true
  end

  class ComponentAccess
    constructor :type, :value, :component, :accessors => true
  end

  class MatrixColumnAccess
    constructor :type, :value, :index, :accessors => true
  end

  class VariableAssignment
    constructor :name, :value, :accessors => true
  end

  class MatMulMat
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.split(" ").last.to_sym
    end
  end

  class MatMulVector
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; true; end

    def type
      signature.split(" ").last.to_sym
    end
  end

  class MatMulScalar
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.split(" ").last.to_sym
    end
  end

  class VectorMulVector
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.split(" ").last.to_sym
    end
  end

  class VectorAddVector
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.split(" ").last.to_sym
    end
  end

  class VectorSubVector
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; true; end

    def type
      signature.split(" ").last.to_sym
    end
  end

  class VectorMulScalar
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.split(" ").sort.last.to_sym
    end
  end

  class VectorDivScalar
    constructor :a, :b, :signature, :accessors => true

    def associative?; false; end

    def type
      signature.split(" ").sort.last.to_sym
    end
  end

  class ScalarMulScalar
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.include?("float") ? :float : :int
    end
  end

  class ScalarDivScalar
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.include?("float") ? :float : :int
    end
  end

  class ScalarAddScalar
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.include?("float") ? :float : :int
    end
  end

  class ScalarSubScalar
    constructor :a, :b, :signature, :accessors => true

    def self.strict_types?; false; end

    def type
      signature.include?("float") ? :float : :int
    end
  end

  class Condition;
    def self.strict_types?; false; end
  end

  class CompEqScalar < Condition
    constructor :a, :b, :signature, :accessors => true
  end

  class CompEqVector < Condition
    constructor :a, :b, :signature, :accessors => true
  end

  class CompLessScalar < Condition
    constructor :a, :b, :signature, :accessors => true
  end

  class CompLessVector < Condition
    constructor :a, :b, :signature, :accessors => true
  end

  class CompGreaterScalar < Condition
    constructor :a, :b, :signature, :accessors => true
  end

  class CompGreaterVector < Condition
    constructor :a, :b, :signature, :accessors => true
  end

  class Function
    constructor :name, :arguments, :type, :body, :builtin, :accessors => true

    def signature
      "#{type} = f(#{arguments.map {|name, value| value.type }.join(", ")})"
    end

    def builtin?
      builtin
    end

  end

  class FunctionCall
    constructor :name, :arguments, :type, :accessors => true
  end

  class If
    constructor :condition, :then_body, :else_body, :accessors => true
  end

  class For
    constructor :init, :condition, :iterator, :body, :accessors => true
  end

  class While
    constructor :condition, :body, :accessors => true
  end

  class Return
    constructor :value, :accessors => true
  end

  class Program
    constructor :root_scope, :functions, :accessors => true

    def register_function(func)
      functions[func.name] ||= []
      functions[func.name]  << func
    end

  end

  class Scope
    def initialize(parent, *initial)
      @parent = parent
      @local = initial.first || {}
    end

    def [](key)
      @local[key] || (@parent || {})[key]
    end

    def include?(key)
      not self[key].nil?
    end

    def register_variable(name, type)
      throw "Value can not be of magic type" if type.nil?

      @local[name] = type
    end

    def branch
      Scope.new(self)
    end

    def clone
      Scope.new(@parent, @local.clone)
    end

  end

end
