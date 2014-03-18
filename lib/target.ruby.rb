module NLSE
  module Target
    module Ruby

      #
      # The runtime module for the Ruby target. This module contains all classes, functions and constants
      # required for transformer generated code to run.
      #
      module Runtime

        class Vec2
          attr_accessor :x, :y

          def self.zero
            Vec2.new(0.0, 0.0)
          end

          def initialize(x, y)
            @x = x
            @y = y
          end

          def *(other)
            if other.is_a?(Vec2)
              (x * other.x) + (y * other.y)
            else
              Vec2.new(x * other, y * other)
            end
          end

          def /(other)
            if other.is_a? Vec2
              Vec2.new(x / other.x, y / other.y)
            else
              Vec2.new(x / other, y / other)
            end
          end

          def %(other)
            Vec2.new(x % other, y % other)
          end

          def +(other)
            if other.is_a? Vec2
              Vec2.new(x + other.x, y + other.y)
            end
          end

          def -(other)
            if other.is_a? Vec2
              Vec2.new(x - other.x, y - other.y)
            else
              Vec2.new(x - other, y - other)
            end
          end

          def to_a
            [ x, y ]
          end

          def to_html
            to_a.map {|e| "<span class=\"comp\">#{e}</span>" }.join
          end
        end
        class Vec3
          attr_accessor :x, :y, :z

          def self.zero
            Vec3.new(0.0, 0.0, 0.0)
          end

          def initialize(x, y, z = nil)
            if z.nil?
              @x = x.x
              @y = x.y
              @z = y
            else
              @x = x
              @y = y
              @z = z
            end
          end

          def xy
            Vec2.new(@x, @y)
          end

          def *(other)
            if other.is_a?(Vec3)
              (x * other.x) + (y * other.y) + (z * other.z)
            else
              Vec3.new(x * other, y * other, z * other)
            end
          end

          def /(other)
            if other.is_a? Vec3
              Vec3.new(x / other.x, y / other.y, z / other.z)
            else
              Vec3.new(x / other, y / other, z / other)
            end
          end

          def %(other)
            Vec3.new(x % other, y % other, z % other)
          end

          def -(other)
            if other.is_a? Vec3
              Vec3.new(x - other.x, y - other.y, z - other.z)
            else
              Vec3.new(x - other, y - other, z - other)
            end
          end

          def +(other)
            if other.is_a? Vec3
              Vec3.new(x + other.x, y + other.y, z + other.z)
            end
          end

          def to_a
            [ x, y, z ]
          end


          def to_html
            to_a.map {|e| "<span class=\"comp\">#{e}</span>" }.join
          end

        end
        class Vec4
          attr_accessor :x, :y, :z, :w

          def self.zero
            Vec4.new(0.0, 0.0, 0.0, 0.0)
          end

          def initialize(x, y, z = nil, w = nil)
            if z.nil?
              @x = x.x
              @y = x.y
              @z = x.z
              @w = y
            elsif w.nil?
              @x = x.x
              @y = x.y
              @z = y
              @w = z
            else
              @x = x
              @y = y
              @z = z
              @w = w
            end
          end

          def xy
            Vec2.new(@x, @y)
          end
          def xyz
            Vec3.new(@x, @y, @z)
          end

          def *(other)
            if other.is_a?(Vec4)
              (x * other.x) + (y * other.y) + (z * other.z) + (w * other.w)
            else
              Vec4.new(x * other, y * other, z * other, w * other)
            end
          end

          def +(other)
            if other.is_a? Vec4
              Vec4.new(x + other.x, y + other.y, z + other.z, w + other.w)
            end
          end

          def -(other)
            if other.is_a? Vec4
              Vec4.new(x - other.x, y - other.y, z - other.z, w - other.w)
            else
              Vec4.new(x - other, y - other, z - other, w - other)
            end
          end

          def /(other)
            if other.is_a? Vec4
              Vec4.new(x / other.x, y / other.y, z / other.z, w / other.w)
            else
              Vec4.new(x / other, y / other, z / other, w / other)
            end
          end

          def %(other)
            Vec4.new(x % other, y % other, z % other, w % other)
          end

          def to_a
            [ x, y, z, w ]
          end

          def to_html
            to_a.join(" ")
          end

        end

        #
        # A matrix class representing values in column wise order. So a matrix
        #   1 0 0
        #   0 0 2
        #   0 3 0
        # is stored as 1 0 0, 0 0 3, 0 2 0 and NOT 1 0 0, 0 0 2, 0 3 0
        #
        class Mat
          attr_reader :m

          def initialize(size, values)
            raise "Not enough values" unless values.length >= size**2

            @size = size
            @m = values
          end

          def [](idx)
            args = @m[(idx * @size)...((idx + 1) * @size)]
            vector_type.send(:new, *args)
          end

          def *(other)
            if other.is_a? vector_type
              trans = transpose
              values = (0...@size).map {|e| trans[e] * other }
              vector_type.send(:new, *values)
            elsif other.is_a? Numeric
              @m = @m.map {|e| e * other }
            else
              raise "Cannot multiply a matrix with #{other}"
            end
          end

          def vector_type
            case @size
              when 2 then Vec2
              when 3 then Vec3
              when 4 then Vec4
            end
          end

          def transpose
            newvalues = (0...@size).map {|row| (0...@size).map {|col| @m[(col * @size) + row] } }.flatten
            Mat.new(@size, newvalues)
          end

          def to_s
            (0...@size).map {|row| (0...@size).map {|col| @m[(col * @size) + row] }.join(" ") }.join("\n")
          end

        end


        def vec2(x, y); Vec2.new(x, y); end
        def vec3(x, y, z = nil); Vec3.new(x, y, z); end
        def vec4(x, y, z = nil, w = nil); Vec4.new(x, y, z, w); end
        def mat2(*args); Mat.new(2, args); end
        def mat3(*args); Mat.new(3, args); end
        def mat4(*args); Mat.new(4, args); end
        def int(x); x.to_i; end
        def float(x); x.to_f; end
        def sin(x); Math.sin(x); end
        def cos(x); Math.cos(x); end
        def tan(x); Math.tan(x); end
        def sqrt(x); Math.sqrt(x); end
        def ceil(x); x.ceil; end
        def floor(x); x.floor; end
        def length(x); sqrt(x.to_a.map {|a| a * a }.inject(0.0) {|m,e| m+e}); end
        def normalize(vec); vec / length(vec); end
        def clamp(x, min, max)
          if [ Vec2, Vec3, Vec4 ].any?{|t| x.is_a? t}
            min = min.to_a
            max = max.to_a
            comps = x.to_a.each_with_index.map {|c, i| clamp(c, min[i], max[i]) }
            x.class.new(*comps)
          else
            x < min ? min : (x > max ? max : x)
          end
        end
        def _extr(a, b, &comp)
          if [ Vec2, Vec3, Vec4 ].any?{|t| a.is_a? t }
            b = (b.respond_to? :to_a) ? b.to_a : a.to_a.map { b }
            result = a.to_a.zip(b).map {|x, y| _extr(x, y, &comp) }
            a.class.new *result
          else
            yield a, b
          end
        end
        def min(a, b); _extr(a, b) {|x, y| x < y ? x : y }; end
        def max(a, b); _extr(a, b) {|x, y| x > y ? x : y }; end
        def abs(a)
          if [ Vec2, Vec3, Vec4 ].any?{|t| a.is_a? t }
            result = a.to_a.map {|x| abs(x) }
            a.class.new *result
          else
            a * (a < 0 ? -1 : 1)
          end
        end
      end

      #
      # Base class for ruby environment shaders
      #
      class Shader

        def bind_uniform(uniforms)
          uniforms.each do |kv|
            name, value = kv
            raise "Unknown uniform: #{name}" unless uniform_exists? name
            instance_variable_set("@#{name}", value)
            self.class.__send__(:attr_accessor, name) unless respond_to? name
          end
          self
        end

        def uniform_state
          known_uniforms.inject({}) {|r, uniform| r[uniform] = self.__send__(uniform); r }
        end

      end

      #
      # Serves as interface between geometry shader code and the rest of the world
      #
      class GeometryShader
        attr_reader :shader

        def initialize(shader)
          raise "Shader is not a NLSE::Target::Ruby::Shader" unless shader.is_a? Shader
          @shader = shader
        end

        def execute(time, resolution, fragCount, fragCoord, fragNormal)
          @shader.bind_uniform(
              :iGlobalTime => time,
              :iResolution => resolution,
              :iFragCount => fragCount,
              :iFragCoord => fragCoord,
              :iFragNormal => fragNormal,
              :sd_FragCoord => 0,
              :sd_FragNormal => 0
          )
          @shader.main
          raise "Shader did not set fragment coordinates" if @shader.sd_FragCoord.nil?
          raise "Shader did not set fragment normal" if @shader.sd_FragNormal.nil?

          [ @shader.sd_FragCoord, @shader.sd_FragNormal ]
        end

        def custom_uniforms
          shader.known_uniforms - [ :iGlobalTime, :iResolution, :iFragCount, :iFragCoord, :iFragNormal, :sd_FragCoord, :sd_FragNormal ]
        end

      end

      #
      # Serves as interface between fragment shader code and the rest of the world
      #
      class FragmentShader
        attr_reader :shader

        def initialize(shader)
          raise "Shader is not a NLSE::Target::Ruby::Shader" unless shader.is_a? Shader
          @shader = shader
        end

        def execute(time, fragCoord, fragNormal)
          @shader.bind_uniform(
              :iGlobalTime => time,
              :iFragCoord => fragCoord,
              :iFragNormal => fragNormal,
              :sd_FragHeight => 0,
              :sd_FragAngle => 0
          )
          @shader.main
          raise "Shader did not set fragment height" if @shader.sd_FragHeight.nil?
          raise "Shader did not set fragment angle" if @shader.sd_FragAngle.nil?

          [ @shader.sd_FragHeight, @shader.sd_FragAngle ]
        end

        def custom_uniforms
          shader.known_uniforms - [ :iGlobalTime, :iFragCoord, :iFragNormal, :sd_FragHeight, :sd_FragAngle ]
        end

      end

      #
      # Serves as interface between pixel shader code and the rest of the world
      #
      class PixelShader
        attr_reader :shader

        def initialize(shader)
          @shader = shader
        end

        def execute(time, fragCoord, fragNormal, pixelCoord, pixelResolution)
          @shader.bind_uniform(
              :iGlobalTime => time,
              :iFragCoord => fragCoord,
              :iFragNormal => fragNormal,
              :iPixelCoord => pixelCoord,
              :iPixelResolution => pixelResolution,
              :sd_PixelColor => 0
          )

          @shader.known_uniforms.each do |uniform|
            raise "Unbound uniform: #{uniform}" if @shader.__send__(uniform).nil?
          end

          @shader.main
          raise "Shader did not set pixel color" if @shader.sd_PixelColor.nil?

          @shader.sd_PixelColor
        end

        def custom_uniforms
          shader.known_uniforms - [ :iGlobalTime, :iFragCoord, :iFragNormal, :iPixelCoord, :iPixelResolution, :sd_PixelColor ]
        end
        
      end

      #
      # The device profile specifying hardware details such as the pixel resolution
      # per fragment or the maximum speed with which the display can change shape.
      #
      class DeviceProfile
        attr_reader :pixel_resolution

        def initialize(pixel_resolution = NLSE::Target::Ruby::Runtime::Vec2.new(1, 1))
          @pixel_resolution = pixel_resolution
        end

      end

      class GeometryShaderRuntimeException < Exception
      end
      class FragmentShaderRuntimeException < Exception
      end
      class PixelShaderRuntimeException < Exception
      end

      #
      # Utility class to execute shaders in a Ruby environment. This class takes care of
      # managing built-in uniforms, updating iGlobalTime and executing the shaders correctly.
      #
      class Engine
        attr_accessor :profile, :arrangement, :geometry_shader, :use_geometry_shader, :fragment_shader, :pixel_shader, :use_pixel_shader
        attr_reader :fragment_resolution

        def initialize(profile = nil, arrangement = nil, geometry_shader = nil, fragment_shader = nil, pixel_shader = nil)
          @profile = profile
          @arrangement = arrangement
          @fragment_resolution = compute_fragment_resolution
          @geometry_shader = geometry_shader
          @use_geometry_shader = false
          @fragment_shader = fragment_shader
          @pixel_shader = pixel_shader
          @use_pixel_shader = false

          reset_time
        end

        #
        # Resets the global time marker of this engine, restarting the iGlobalTime uniform
        #
        def reset_time
          @start_time = Time.now
        end

        #
        # Executes one shader run and returns an array with frag_count Runtime::Vec4 colors
        # where the index corresponds to the respective FragID
        #
        def execute
          geometry = fragment = pixel = []

          current_time = Time.now
          begin
            geometry = geometry_shader.nil? ? arrangement : compute_geometry(arrangement, current_time)
          rescue => e
            raise GeometryShaderRuntimeException, e
          end

          begin
            fragment = fragment_shader.nil? ? [] : compute_fragment(geometry, current_time)
          rescue => e
            raise FragmentShaderRuntimeException, e
          end

          begin
            pixel    = pixel_shader.nil?    ? [] : compute_pixel(geometry, current_time)
          rescue => e
            raise PixelShaderRuntimeException, e
          end

          [ geometry, fragment, pixel ]
        end

        #
        # Computes the pixel values each fragment.
        #
        def compute_pixel(geometry, current_time = Time.now)
          time = (current_time - @start_time)
          geometry.map do |geom|
            (0...@profile.pixel_resolution.x).map do |x|
              (0...@profile.pixel_resolution.y).map do |y|
                pixelCoord = NLSE::Target::Ruby::Runtime::Vec2.new(x, y)
                pixel_shader.execute(time, geom.first, geom.last, pixelCoord, @profile.pixel_resolution)
              end
            end.flatten
          end
        end

        #
        # Computes the fragment state for the given geometry.
        #
        def compute_fragment(geometry, current_time = Time.now)
          time = (current_time - @start_time)
          geometry.map {|geom| fragment_shader.execute(time, geom.first, geom.last) }
        end

        #
        # Computes the geometry based on the arrangement. Returns an array of frag_count
        # [ position, normal ].
        #
        def compute_geometry(arrangement, current_time = Time.now)
          time = (current_time - @start_time)

          arrangement.map {|frag| geometry_shader.execute(time, fragment_resolution, arrangement.length, frag.first, frag.last) }
        end

        def arrangement=(value)
          @arrangement = value
          @fragment_resolution = compute_fragment_resolution
        end

        def compute_fragment_resolution
          return NLSE::Target::Ruby::Runtime::Vec3.new(0, 0, 0) if arrangement.nil?

          lo,hi = arrangement.inject([ [ nil, nil, nil ], [ nil, nil, nil ] ]) do |m, e|
            lo, hi = m

            lo = arrangement.map {|f| f[0].to_a }.inject(lo) {|l, e| e.zip(l).map {|k| min(k.first, k.last) } }
            hi = arrangement.map {|f| f[0].to_a }.inject(hi) {|l, e| e.zip(l).map {|k| max(k.first, k.last) } }

            [ lo, hi ]
          end
          resolution = lo.zip(hi).map {|e| e.last - e.first }
          NLSE::Target::Ruby::Runtime::Vec3.new(resolution[0], resolution[1], resolution[2])
        end

        private
        # thanks to the non-existent Math support in opal we need to implement min/max ourselves
        def min(a, b); (b.nil? or a < b) ? a : b; end
        def max(a, b); (b.nil? or a > b) ? a : b; end

      end

      #
      # Generates Ruby code out of NLSE code
      #
      class Transformer
        attr_accessor :class_name

        def initialize(class_name = "NLSLProgram")
          @class_name = class_name
        end

        def transform(element, sep = nil)
          (element.is_a?(Array) ? element : [ element ]).map do |root|
            name = root.class.name.split("::").last
            rule = "transform_#{name.downcase}"
            if respond_to? rule
              send(rule.to_sym, root)
            else
              puts "WARNING: No rule for #{name} (looking for #{rule}(root)"
            end
          end.join sep
        end

        def transform_program(root)
          """
          class #{class_name} < NLSE::Target::Ruby::Shader
            include NLSE::Target::Ruby::Runtime

            UNIFORMS = { #{root.uniforms.map {|k,v| ":#{k} => :#{v.type}" }.join(", ")} }

            #{transform root.uniforms.values}
            #{transform root.functions.values.flatten.reject {|e| e.builtin? }}

            def initialize
              #{transform_uniform_init root.uniforms.values}
            end

            def known_uniforms
              UNIFORMS.keys
            end

            def uniform_type(name)
              UNIFORMS[name]
            end

            def uniform_exists?(name)
              known_uniforms.include?(name)
            end
          end
          """
        end

        def transform_uniform(root)
          "attr_accessor :#{root.name}\n"
        end

        def transform_uniform_init(root)
          root.map do |uniform|
            value = case uniform.type
              when :vec2; "vec2(0.0, 0.0)"
              when :vec3; "vec3(0.0, 0.0, 0.0)"
              when :vec4; "vec4(0.0, 0.0, 0.0, 0.0)"
              when :float; "1.0"
              when :int; "1"
              when :sampler1D; []
              when :sampler2D; []
              when :sampler3D; []
              when :sampler4D; []
             end

            "@#{uniform.name} = #{value}"
          end.join("\n")
        end

        def transform_function(root)
          """
          def #{root.name}(#{root.arguments.keys.join(", ")})
            #{transform root.body, "\n            "}
          end
          """
        end

        def transform_return(root)
          "#{transform root.value}\n"
        end

        def transform_value(root)
          root.value.to_s
        end

        def transform_variableassignment(root)
          "#{root.name} = #{transform root.value}"
        end

        def transform_uniformassignment(root)
          "@#{root.name} = #{transform root.value}"
        end

        def transform_componentaccess(root)
          "#{transform root.value}.#{root.component}"
        end

        def transform_matrixcolumnaccess(root)
          "#{transform root.value}[#{transform root.index}]"
        end

        def transform_sampleraccess(root)
          "#{transform root.value}[#{transform root.index}]"
        end

        def transform_functioncall(root)
          "#{root.name}(#{transform root.arguments, ", "})"
        end

        def transform_if(root)
          elze = root.else_body.nil? ? "" : "else\n#{transform root.else_body, "\n"}"

          "if (#{transform root.condition})\n#{transform root.then_body, "\n"}#{elze}\nend"
        end

        def transform_for(root)
          init = transform root.init
          cond = transform root.condition
          iter = transform root.iterator
          body = transform root.body, "\n"

          [
              "if true",
              init,
              "while (#{cond})",
              body,
              iter,
              "end",
              "end"
          ].join("\n")
        end

        def transform_while(root)
          cond = transform root.condition
          body = transform root.body

          "while (#{cond})\n#{body}\nend"
        end

        def transform_scalardivscalar(root)
          "(#{transform root.a} / #{transform root.b})"
        end

        def transform_scalarmodscalar(root)
          "(#{transform root.a} % #{transform root.b})"
        end

        def transform_scalarmulscalar(root)
          "(#{transform root.a} * #{transform root.b})"
        end

        def transform_scalaraddscalar(root)
          "(#{transform root.a} + #{transform root.b})"
        end

        def transform_scalarsubscalar(root)
          "(#{transform root.a} - #{transform root.b})"
        end

        def transform_compeqscalar(root)
          "(#{transform root.a} == #{transform root.b})"
        end

        def transform_compeqvector(root)
          "(#{transform root.a} == #{transform root.b})"
        end

        def transform_complessscalar(root)
          "(#{transform root.a} < #{transform root.b})"
        end

        def transform_complessvector(root)
          "(#{transform root.a} < #{transform root.b})"
        end

        def transform_compgreaterscalar(root)
          "(#{transform root.a} > #{transform root.b})"
        end

        def transform_compgreatervector(root)
          "(#{transform root.a} > #{transform root.b})"
        end

        def transform_vectoraddvector(root)
          "(#{transform root.a} + #{transform root.b})"
        end

        def transform_vectormulscalar(root)
          "(#{transform root.a} * #{transform root.b})"
        end

        def transform_vectorsubvector(root)
          "(#{transform root.a} - #{transform root.b})"
        end

        def transform_vectorsubscalar(root)
          "(#{transform root.a} - #{transform root.b})"
        end

        def transform_vectordivscalar(root)
          "(#{transform root.a} / #{transform root.b})"
        end

        def transform_vectordivvector(root)
          "(#{transform root.a} / #{transform root.b})"
        end

        def transform_vectormodscalar(root)
          "(#{transform root.a} / #{transform root.b})"
        end

        def transform_vectormulvector(root)
          "(#{transform root.a} * #{transform root.b})"
        end

        def transform_matmulvector(root)
          "(#{transform root.a} * #{transform root.b})"
        end

      end

      end
    end
end
