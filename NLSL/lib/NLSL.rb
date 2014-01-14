#
# NLSL = NanoLite Shader Language
#
# This contains modules which are attached to the AST during parsing. They provide an API to traverse
# the resulting AST in a semantic manner. Specs for these modules are in the AST_*_spec.rb files.
#
module NLSL

  module Program

    def content
      ast_children
    end

  end

  module Comment

    def value
      text_value.strip
    end

  end

  module FunctionArguments

    def content
      r  = elements.select {|e| e.is_a?(Expression) }
      r += elements.last.elements.map {|e| e.ast_children }
      r.flatten
    end

  end

  module FunctionDefinition

    def return_type
      rettype.text_value
    end

    def name
      elements.select {|e| e.is_a? Identifier }.first.text_value
    end

    def arguments
      descendant.select {|e| e.is_a? FunctionArgumentDefinition }
    end

    def body
      descendant.select {|e| e.is_a? FunctionBody }.first
    end

  end

  module FunctionArgumentDefinition

    def type
      descendant.select {|e| e.is_a? TypeExpression }.first.text_value
    end

    def name
      descendant.select {|e| e.is_a? Identifier }.first.text_value
    end

  end

  module FunctionBody

    def statements
      ast_children
    end

  end

  module FunctionCall

    def name
      descendant.select {|e| e.is_a? Identifier }.first.text_value
    end

    def arguments
      args = elements.select {|e| e.is_a? FunctionArguments }.first
      args.nil? ? [] : args.content
    end

  end

  module Statement

    def content
      ast_children
    end

  end

  module VectorComponent

    def value
      text_value.strip[1..-1]
    end

  end

  module NumberLiteral

    def int?
      not text_value.include?('.')
    end

    def value
      int? ? text_value.strip.to_i : text_value.strip.to_f
    end

  end

  module Identifier

    def value
      text_value.strip
    end

  end

  module UnaryAssignment

    def name
      identifier.text_value
    end

    def operator
      unary_operator.text_value
    end

    def prefix?
      ast_children.first.is_a? Operator
    end

  end

  module Assignment

    def type
      elements[0].vartype.text_value if elements[0].respond_to? :vartype
    end

    def name
      identifier.text_value
    end

    def expression
      elements.select {|e| e.is_a? Expression }.first
    end

  end

  module TypeExpression
  end

  module If

    def condition
      comparative
    end

    def then_body
      funcbody.ast_children
    end

    def else_body
      elements.select {|a| a.is_a? Ifelse0 }.first.funcbody.ast_children
    end

  end

  module While

    def condition
      comparative
    end

    def body
      funcbody.ast_children.first
    end

  end

  module For

    def initialization
      assignment
    end

    def condition
      comparative
    end

    def iterator
      (elements.select {|e| e.is_a? Assignment } + elements.select {|e| e.is_a? UnaryAssignment }).last
    end

    def body
      funcbody.ast_children.first
    end

  end

  module Return

    def expression
      ast_children.first
    end

  end

  module Expression

    def content
      ast_children
    end

  end

  module OperationalExpression

    def factors
      ast_children.reject {|e| e.ast_module == Operator }
    end

    def operator
      r = elements.select {|e| e.is_a? Operator }.first
      r.nil? ? nil : r.value
    end

  end

  module VariableRef

    def value
      elements.select {|e| e.is_a? Identifier }.first.value
    end

    def component
      r = elements.select {|e| e.is_a? VectorComponent }.first
      r.nil? ? nil : r.value
    end

  end

  module Operator

    def value
      text_value.strip
    end

  end

end