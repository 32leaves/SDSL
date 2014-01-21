module NLSL
  module Compiler

    #
    # The set of uniforms that are common to all shader types
    #
    _COMMON_BUILTIN_UNIFORMS = [
      NLSE::Uniform.new(:name => :iGlobalTime, :type => :float),
      NLSE::Uniform.new(:name => :iResolution, :type => :vec3)
    ]
    #
    # The set of uniforms per shader type
    #
    BUILTIN_UNIFORMS = {
        :geometry => _COMMON_BUILTIN_UNIFORMS + [
          NLSE::Uniform.new(:name => :iFragCount, :type => :int),
          NLSE::Uniform.new(:name => :iFragID, :type => :int),
          NLSE::Uniform.new(:name => :nl_FragCoord, :type => :vec3),
        ],
        :color => _COMMON_BUILTIN_UNIFORMS + [
          NLSE::Uniform.new(:name => :iFragCoord, :type => :vec3),
          NLSE::Uniform.new(:name => :nl_FragColor, :type => :vec4),
        ]
    }

    def self._mkbfunc(name, types, rettype)
      arguments = types.each_with_index.inject({}) {|m, v| m[v.last] = NLSE::Value.new(:type => v.first, :value => nil, :ref => false); m }
      NLSE::Function.new(:name => name, :arguments => arguments, :type => rettype, :body => [], :builtin => true)
    end
    #
    # The root registration of built-in functions. These functions have to be supported by the runtime
    #
    BUILTIN_FUNCTIONS = [
      _mkbfunc("vec4", [ :float, :float, :float, :float ], :vec4),
      _mkbfunc("vec4", [ :vec2, :float, :float ], :vec4),
      _mkbfunc("vec4", [ :vec3, :float ], :vec4),
      _mkbfunc("vec3", [ :float, :float, :float ], :vec3),
      _mkbfunc("vec3", [ :vec2, :float ], :vec3),
      _mkbfunc("vec2", [ :float, :float ], :vec2),
      _mkbfunc("mat4", 16.times.map { :float }, :mat4),
      _mkbfunc("mat4", [ :vec4, :vec4, :vec4, :vec4 ], :mat4),
      _mkbfunc("mat3", 9.times.map { :float }, :mat3),
      _mkbfunc("mat3", [ :vec3, :vec3, :vec3 ], :mat3),
      _mkbfunc("mat2", [ :float, :float, :float, :float ], :mat2),
      _mkbfunc("mat2", [ :vec2, :vec2 ], :mat2),
      _mkbfunc("cos", [ :float ], :float),
      _mkbfunc("cos", [ :int ], :float),
      _mkbfunc("sin", [ :float ], :float),
      _mkbfunc("sin", [ :int ], :float),
    ]

    #######
    ## Signature convention for enabling non-strict types:
    ##   - types ordered in reverse alphabetical order
    ##   - operator comes first
    ##
    ##
    OPERATIONS = {
      # mul and div
      "* mat4 mat4" => NLSE::MatMulMat,
      "* mat3 mat3" => NLSE::MatMulMat,
      "* mat2 mat2" => NLSE::MatMulMat,
      "* mat4 vec4" => NLSE::MatMulVector,
      "* mat3 vec3" => NLSE::MatMulVector,
      "* mat2 vec2" => NLSE::MatMulVector,
      "* mat4 float" => NLSE::MatMulScalar,
      "* mat4 int" => NLSE::MatMulScalar,
      "* mat3 float" => NLSE::MatMulScalar,
      "* mat3 int" => NLSE::MatMulScalar,
      "* mat2 float" => NLSE::MatMulScalar,
      "* mat2 int" => NLSE::MatMulScalar,
      "* vec4 float" => NLSE::VectorMulScalar,
      "* vec4 int" => NLSE::VectorMulScalar,
      "/ vec4 float" => NLSE::VectorDivScalar,
      "/ vec4 int" => NLSE::VectorDivScalar,
      "* vec3 float" => NLSE::VectorMulScalar,
      "* vec3 int" => NLSE::VectorMulScalar,
      "/ vec3 float" => NLSE::VectorDivScalar,
      "/ vec3 int" => NLSE::VectorDivScalar,
      "* vec2 float" => NLSE::VectorMulScalar,
      "* vec2 int" => NLSE::VectorMulScalar,
      "/ vec2 float" => NLSE::VectorDivScalar,
      "/ vec2 int" => NLSE::VectorDivScalar,
      "* vec4 vec4" => NLSE::VectorMulVector,
      "* vec3 vec3" => NLSE::VectorMulVector,
      "* vec2 vec2" => NLSE::VectorMulVector,
      "* int float" => NLSE::ScalarMulScalar,
      "* int int" => NLSE::ScalarMulScalar,
      "* float float" => NLSE::ScalarMulScalar,
      "/ int float" => NLSE::ScalarDivScalar,
      "/ int int" => NLSE::ScalarDivScalar,
      "/ float float" => NLSE::ScalarDivScalar,

      # add and sub
      "+ vec4 vec4" => NLSE::VectorAddVector,
      "+ vec3 vec3" => NLSE::VectorAddVector,
      "+ vec2 vec2" => NLSE::VectorAddVector,
      "+ float float" => NLSE::ScalarAddScalar,
      "+ int float" => NLSE::ScalarAddScalar,
      "+ int int" => NLSE::ScalarAddScalar,
      "- vec4 vec4" => NLSE::VectorSubVector,
      "- vec3 vec3" => NLSE::VectorSubVector,
      "- vec2 vec2" => NLSE::VectorSubVector,
      "- float float" => NLSE::ScalarSubScalar,
      "- int float" => NLSE::ScalarSubScalar,
      "- int int" => NLSE::ScalarSubScalar,

      # equality
      "== int float" => NLSE::CompEqScalar,
      "== float float" => NLSE::CompEqScalar,
      "== int int" => NLSE::CompEqScalar,
      "== vec4 vec4" => NLSE::CompEqVector,
      "== vec3 vec3" => NLSE::CompEqVector,
      "== vec2 vec2" => NLSE::CompEqVector,

      # less and greater
      "< int float" => NLSE::CompLessScalar,
      "< float float" => NLSE::CompLessScalar,
      "< int int" => NLSE::CompLessScalar,
      "< vec4 vec4" => NLSE::CompLessVector,
      "< vec3 vec3" => NLSE::CompLessVector,
      "< vec2 vec2" => NLSE::CompLessVector,
      "> int float" => NLSE::CompGreaterScalar,
      "> float float" => NLSE::CompGreaterScalar,
      "> int int" => NLSE::CompGreaterScalar,
      "> vec4 vec4" => NLSE::CompGreaterVector,
      "> vec3 vec3" => NLSE::CompGreaterVector,
      "> vec2 vec2" => NLSE::CompGreaterVector,
    }

    #
    # All vector components, their result type and to which vector they're applicable
    #
    VECTOR_COMPONENTS = {
      :x => [ :float, [ :vec4, :vec3, :vec2 ] ],
      :y => [ :float, [ :vec4, :vec3, :vec2 ] ],
      :z => [ :float, [ :vec4, :vec3 ] ],
      :w => [ :float, [ :vec4 ] ],
      :xy => [ :vec2, [ :vec4, :vec3 ] ],
      :xyz => [ :vec3, [ :vec4 ] ]
    }

    #
    # Maps how column wise matrix access translates to vectors for which matrix type
    # and how many columns a matrix type has
    #
    MATRIX_ARRAY_ACCESS = {
      :mat4 => [4, :vec4],
      :mat3 => [3, :vec3],
      :mat2 => [2, :vec2]
    }

    #
    # Error class raised in case of a compiler error
    #
    class CompilerError < StandardError
      constructor :message, :context, :accessors => true

      def line
        @context.input[0..@context.interval.begin].count("\n") + 1
      end

      #
      # Falls back to to_s to make the debug output look nice. Use message! to get the message only
      #
      def message
        to_s
      end

      #
      # Only the message
      #
      def message!
        @message
      end

      def to_s
        "#{@message}\nSomewhere in line #{line} near: #{@context.text_value}\n\n"
      end

    end

    #
    # Transforms an NLSL AST into NLSE code, performs type-checking and linking in the process
    #
    class Transformer

      def initialize(shader_type)
        throw "Unknown shader type #{shader_type}" unless shader_type == :color or shader_type == :geometry
        @shader_type = shader_type
      end

      def transform(element, scope = nil, program = nil)
        _error element, "Scope is not a NLSE::Scope" unless scope.is_a? NLSE::Scope or scope.nil?
        _error element, "Program is not a NLSE::Program" unless program.is_a?(NLSE::Program) or program.nil?
        _error element, "Element is nil" if element.nil?

        if(element.is_a? Program)
          transform_program(element, scope, program)
        elsif element.is_a? UniformDefinition
          transform_uniform(element, scope, program)
        elsif element.is_a? FunctionDefinition
          transform_function(element, scope, program)
        elsif element.is_a? FunctionArgumentDefinition
          transform_argdef(element, scope, program)
        elsif element.is_a? Statement or element.is_a? Expression
          transform(element.content.first, scope, program)
        elsif element.is_a? Assignment
          transform_assignment(element, scope, program)
        elsif element.is_a? UnaryAssignment
          transform_unaryassignment(element, scope, program)
        elsif element.is_a? OperationalExpression
          transform_opexp(element, scope, program)
        elsif element.is_a? NumberLiteral
          transform_numlit(element, scope, program)
        elsif element.is_a? VariableRef
          transform_varref(element, scope, program)
        elsif element.is_a? FunctionCall
          transform_funccal(element, scope, program)
        elsif element.is_a? Comment
          NLSE::Comment.new(:value => element.value[2..-1])
        elsif element.is_a? If
          transform_if(element, scope, program)
        elsif element.is_a? While
          transform_while(element, scope, program)
        elsif element.is_a? For
          transform_for(element, scope, program)
        elsif element.is_a? Return
          transform_return(element, scope, program)
        else
          puts "Unhandled AST element: #{element.ast_module}"
        end
      end

      def transform_program(element, scope, program)
        r = NLSE::Program.new(BUILTIN_FUNCTIONS, BUILTIN_UNIFORMS[@shader_type])
        element.content.each {|c| transform(c, r.root_scope, r) }
        r
      end

      def transform_uniform(element, scope, program)
        r = NLSE::Uniform.new(:name => element.name.to_sym, :type => element.type.to_sym)
        program.register_uniform(r)
        r
      end

      def transform_function(element, scope, program)
        name = element.name
        type = element.return_type.to_sym
        nuscope = scope.branch
        args = element.arguments.inject({}) {|m,a| m[a.name] = transform(a, nuscope, program); m }
        body = element.body.statements.map {|e| transform(e, nuscope, program) }

        func = NLSE::Function.new(:name => name, :type => type, :arguments => args, :body => body, :builtin => false)
        program.register_function(func)
      end

      def transform_argdef(element, scope, program)
        name = element.name.to_sym
        type = element.type.to_sym

        scope.register_variable(name, type)
      end

      def transform_assignment(element, scope, program)
        name = element.name.to_sym
        value = transform(element.expression, scope, program)
        initial = false

        if element.type.nil?
          _error element, "Unknown variable #{name}" if not scope.include?(name)
          unless value.nil?
            _error element, "Type mismatch for variable \"#{name}\": #{value.type} != #{scope[name]}" if scope[name] != value.type
          end
        else
          _error element, "Type mismatch for variable \"#{name}\": #{value.type} != #{element.type}" if element.type.to_sym != value.type
          initial = true
          scope.register_variable(name, element.type.to_sym)
        end

        NLSE::VariableAssignment.new(:name => name, :value => value, :initial => initial)
      end

      def transform_unaryassignment(element, scope, program)
        name = element.name.to_sym
        _error element, "Unknown variable #{name}" if not scope.include?(name)

        type = scope[name]
        _error element, "Unary assignments only exist for scalar types" unless type == :float or type == :int
        op    = element.operator == "++" ? NLSE::ScalarAddScalar : NLSE::ScalarSubScalar
        opsig = element.operator[-1]

        NLSE::VariableAssignment.new(:name => name, :value => op.new(
            :a => NLSE::Value.new(:type => type, :value => name, :ref => true),
            :b => NLSE::Value.new(:type => :int, :value => 1, :ref => false),
            :signature => "#{opsig} #{[type, :int].sort.reverse.join(" ")}"
        ), :initial => false)
      end

      def transform_opexp(element, scope, program)
        _error element, "OpExp with more than two factors are not yet supported" if element.factors.length > 2

        factors = element.factors.map {|e| transform(e, scope, program) }

        ## try and find with the original signature
        types = factors.map {|e| e.type.to_s }
        signature = "#{element.operator} #{types.first} #{types.last}"
        op = OPERATIONS[signature]
        if op.nil?
          ## try and and find non-strictly typed operation
          types = types.sort.reverse
          nonstrict_signature = "#{element.operator} #{types.first} #{types.last}"
          op = OPERATIONS[nonstrict_signature]

          _error element, "Invalid operation: #{signature}" if op.nil? or op.strict_types?
        end

        op.new(:a => factors.first, :b => factors.last, :signature => signature)
      end

      def transform_numlit(element, scope, program)
        NLSE::Value.new(:type => element.int? ? :int : :float, :value => element.value, :ref => false)
      end

      def transform_varref(element, scope, program)
        name = element.value.to_sym
        _error element, "Unknown variable: #{name}" if not scope.include?(name)

        type = scope[name]
        result = NLSE::Value.new(:type => type, :value => name, :ref => true)

        array = element.array
        if not array.nil?
          access_spec = MATRIX_ARRAY_ACCESS[type]
          _error element, "Array access is only valid for mat2, mat3 or mat4" if access_spec.nil?
          _error element, "Column index out of bounds #{array} > #{type}" if array >= access_spec.first

          type = access_spec.last
          result = NLSE::MatrixColumnAccess.new(:type => type, :value => result, :index => array)
        end

        component = element.component
        if not component.nil?
          componentLookup = VECTOR_COMPONENTS[component.to_sym]
          _error element, "Invalid vector component: #{type}.#{component}" if not componentLookup.last.include?(type)

          result = NLSE::ComponentAccess.new(:type => componentLookup.first, :value => result, :component => component.to_sym)
        end

        result
      end

      def transform_funccal(element, scope, program)
        name = element.name
        funcs = program.functions[name]
        _error element, "Unknown function: #{name}" if funcs.nil?
        funcs = funcs.inject({}) do |m, func|
          signature = func.arguments.values.map {|a| a.type.to_s }.join(", ")
          m[signature] = func
          m
        end

        arguments = element.arguments.map {|a| transform(a, scope, program) }
        signature = arguments.map {|a| a.type.to_s }.join(", ")
        function = funcs[signature]
        _error element, "No function #{name}(#{signature}) found. Candidates are: #{funcs.keys.map {|s| "#{name}(#{s})" }}" if function.nil?

        NLSE::FunctionCall.new(:name => name, :arguments => arguments, :type => function.type)
      end

      def transform_if(element, scope, program)
        condition = transform(element.condition, scope, program)
        _error element, "Conditional must be a comparative expression: #{element.condition}" unless condition.is_a? NLSE::Condition

        then_scope = scope.branch
        then_body = element.then_body.map {|e| transform(e, then_scope, program) }
        else_body = []
        unless element.else_body.nil?
          else_scope = scope.branch
          else_body = element.else_body.map {|e| transform(e, else_scope, program) }
        end

        NLSE::If.new(:condition => condition, :then_body => then_body, :else_body => else_body)
      end

      def transform_while(element, scope, program)
        condition = transform(element.condition, scope, program)
        _error element, "Conditional must be a comparative expression: #{element.condition}" unless condition.is_a? NLSE::Condition

        nuscope = scope.branch
        body = element.body.content.map {|e| transform(e, nuscope, program) }
        NLSE::While.new(:condition => condition, :body => body)
      end

      def transform_for(element, scope, program)
        nuscope = scope.branch
        initialization = transform(element.initialization, nuscope, program)
        iterator = transform(element.iterator, nuscope, program)
        condition = transform(element.condition, nuscope, program)
        _error element, "Conditional must be a comparative expression: #{element.condition}" unless condition.is_a? NLSE::Condition

        body = element.body.content.map {|e| transform(e, nuscope, program) }

        NLSE::For.new(:init => initialization, :iterator => iterator, :condition => condition, :body => body)
      end

      def transform_return(element, scope, program)
        NLSE::Return.new(:value => transform(element.expression, scope, program))
      end

      def _error(element, msg)
        raise CompilerError.new(:context => element, :message => msg)
      end

    end

  end
end
