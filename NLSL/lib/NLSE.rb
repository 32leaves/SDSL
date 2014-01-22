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

    def __children; [ ]; end
  end

  class Value
    constructor :type, :value, :ref, :accessors => true

    def __children; [ ]; end
  end

  class ComponentAccess
    constructor :type, :value, :component, :accessors => true

    def __children; [ value ]; end
  end

  class MatrixColumnAccess
    constructor :type, :value, :index, :accessors => true

    def __children; [ value ]; end
  end

  class VariableAssignment
    constructor :name, :value, :initial, :accessors => true

    def __children; [ value ]; end

    def initial_assignment?
      initial
    end
  end

  #
  # Base class for all binary operations
  #
  class Op
    constructor :a, :b, :signature, :accessors => true

    def __children; [ a, b ]; end

    #
    # True if this operator requires strict typing
    #
    # strictness means that an operator only makes sense when types are in a certain order (e.g., vec div scalar)
    # associativity means that an operator can be applied to an arbitrary operand order (e.g., vec mul vec)
    # strictness is a stronger condition that associativity (e.g., scalar div scalar is not-strict and not associative, however scalar mul scalar is also non-strict but associative)
    #
    def self.strict_types?; false; end
  end

  #
  # Base class for all binary operations involving matrices or vectors
  #
  class VectorOp < Op
    def type
      signature.split(" ").sort.last.to_sym
    end
  end

  class MatMulMat < VectorOp
  end

  class MatMulVector < VectorOp
    def self.strict_types?; true; end
  end

  class MatMulScalar < VectorOp
  end

  class VectorMulVector < VectorOp
    def type; :float; end
  end

  class VectorAddVector < VectorOp
  end

  class VectorSubVector < VectorOp
    def self.strict_types?; true; end
  end

  class VectorMulScalar < VectorOp
  end

  class VectorDivScalar < VectorOp
  end

  class ScalarOp < Op
    def type
      signature.include?("float") ? :float : :int
    end
  end

  class ScalarMulScalar < ScalarOp
  end

  class ScalarDivScalar < ScalarOp
  end

  class ScalarAddScalar < ScalarOp
  end

  class ScalarSubScalar < ScalarOp
  end

  class Condition
    def __children; [ a, b ]; end
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

  class Uniform
    constructor :name, :type, :accessors => true

    def __children; []; end
  end

  class Function
    constructor :name, :arguments, :type, :body, :builtin, :accessors => true

    def __children; [ body ].flatten; end

    def signature
      "#{type} = f(#{arguments.map {|name, value| value.type }.join(", ")})"
    end

    def builtin?
      builtin
    end

  end

  class FunctionCall
    constructor :name, :arguments, :type, :accessors => true

    def __children; [ arguments ].flatten; end
  end

  class If
    constructor :condition, :then_body, :else_body, :accessors => true

    def __children; [ condition, then_body, else_body ].flatten; end
  end

  class For
    constructor :init, :condition, :iterator, :body, :accessors => true

    def __children; [ init, condition, iterator, body ].flatten; end
  end

  class While
    constructor :condition, :body, :accessors => true

    def __children; [ condition, body ].flatten; end
  end

  class Return
    constructor :value, :accessors => true

    def __children; [ value ]; end
  end

  class Program
    attr_reader :root_scope, :functions, :uniforms

    def __children; [ functions.values, uniforms.values ].flatten; end

    def initialize(functions = [], uniforms = [])
      @root_scope = Scope.new(nil)
      @functions = {}
      @uniforms = {}

      functions.each {|f| register_function f }
      uniforms.each {|u| register_uniform u }
    end

    def register_uniform(uniform)
      uniforms[uniform.name] = uniform
      root_scope.register_variable(uniform.name, uniform.type)
    end

    def register_function(func)
      functions[func.name] ||= []
      functions[func.name]  << func
    end

    #
    # Computes a list of uniforms which are used in this program
    #
    def used_uniforms
      uniforms.values.select do |uniform|
        visitor = proc do |node|
          (node.is_a?(Value) and node.ref and node.value == uniform.name and node.type == uniform.type) ?
              true : node.__children.any?(&visitor)
        end
        visitor.call(self)
      end
    end

  end

  class Scope
    def initialize(parent = nil, *initial)
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
