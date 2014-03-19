require_relative 'lib/sdsr'

puts "usage: sdsr <script>" if ARGV.length < 1

filename = ARGV.first || "C:/Users/Christian/Downloads/sdslProgram07032014143309.zip"
loader = SDSR::ZipLoader.new(filename)
engine = loader.build_engine
engine.profile = NLSE::Target::Ruby::DeviceProfile.new
engine.arrangement = NLSE::Target::Ruby::FixedArrangementGenerator.uniform_rect(10)
engine.execute