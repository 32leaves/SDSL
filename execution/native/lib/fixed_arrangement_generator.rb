require_relative '../../../lib/target.ruby'

module SDSR

  # Generates fixed arrangements. This is particularly useful for debugging
  class FixedArrangementGenerator

    # Generates a fixed lattice along XZ with the Y axis as normal
    def self.uniform_rect(x_count, z_count = x_count, x_spacing = 1, z_spacing = 1)
      positions = (0..x_count).map do |x|
        (0..z_count).map do |z|
          NLSE::Target::Ruby::Runtime::Vec3.new(x * x_spacing, 0, z * z_spacing)
        end
      end
      normal = NLSE::Target::Ruby::Runtime::Vec3.new(0, 1, 0)

      positions.flatten.map {|pos| [pos, normal] }
    end

  end

end
