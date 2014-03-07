require 'zip'
require_relative '../../../lib/NLSLParser'
require_relative '../../../lib/NLSE'
require_relative '../../../lib/NLSLtoNLSE'
require_relative '../../../lib/target.ruby'

module SDSR

  #
  # Loads shaders from an IDE generated ZIP file
  #
  class ZipLoader

    def initialize(filename)
      Zip::File.open(filename) do |file|
        @contents = {}
        file.each do |entry|
          @contents[entry.name.split(".").first] = entry.get_input_stream.read
        end
      end
    end

    def build_engine
      geometry = load :geometry rescue nil
      fragment = load :fragment rescue nil
      pixel    = load :pixel rescue nil

      geometry = NLSE::Target::Ruby::GeometryShader.new(geometry) unless geometry.nil?
      fragment = NLSE::Target::Ruby::FragmentShader.new(fragment) unless fragment.nil?
      pixel = NLSE::Target::Ruby::PixelShader.new(pixel) unless pixel.nil?

      NLSE::Target::Ruby::Engine.new(nil, nil, geometry, fragment, pixel)
    end

    # Shortcut for load
    def [](type)
      load type
    end

    # Loads a shader from the ZIP file. Valid types are fragment, geometry, pixel
    def load(type)
      type = type.to_sym
      parser = NLSLParser.new
      parsed = parser.parse @contents[type.to_s]

      nlse = NLSL::Compiler::Transformer.new(type).transform(parsed)
      name = "SG#{type}#{Time.now.to_i}"
      ruby = NLSE::Target::Ruby::Transformer.new(name).transform(nlse)
      eval("#{ruby}\n#{name}.new")
    end

  end

end
