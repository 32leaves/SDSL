
          class SH1396037785743 < NLSE::Target::Ruby::Shader
            include NLSE::Target::Ruby::Runtime

            UNIFORMS = { :iGlobalTime => :float, :iFragCoord => :vec3, :iFragNormal => :vec3, :iPixelResolution => :vec2, :iPixelCoord => :vec2, :sd_PixelColor => :vec4, :red => :float, :green => :float, :blue => :float }

            attr_accessor :iGlobalTime
attr_accessor :iFragCoord
attr_accessor :iFragNormal
attr_accessor :iPixelResolution
attr_accessor :iPixelCoord
attr_accessor :sd_PixelColor
attr_accessor :red
attr_accessor :green
attr_accessor :blue

            
          def main()
            color = (vec3(red, green, blue) * clamp((iFragCoord.z - 1.25), 0.2, 1.0))
            @sd_PixelColor = vec4(color, 1.0)
          end
          

            def initialize
              @iGlobalTime = 1.0
@iFragCoord = vec3(0.0, 0.0, 0.0)
@iFragNormal = vec3(0.0, 0.0, 0.0)
@iPixelResolution = vec2(0.0, 0.0)
@iPixelCoord = vec2(0.0, 0.0)
@sd_PixelColor = vec4(0.0, 0.0, 0.0, 0.0)
@red = 1.0
@green = 1.0
@blue = 1.0
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
          
