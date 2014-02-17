require 'opal'
require 'opal-jquery'
require 'accordion'
require 'THREE'
require 'DatGUI'
require 'ACE'
require 'target.ruby'

#
# Monkey patching the Ruby NLSE runtime to make the math functions work
#
module NLSE
  module Target
    module Ruby
      module Runtime
        def sin(x); `Math.sin(x)`; end
        def cos(x); `Math.cos(x)`; end
        def tan(x); `Math.tan(x)`; end
        def sqrt(x); `Math.sqrt(x)`; end
        def ceil(x); `Math.ceil(x)`; end
        def floor(x); `Math.floor(x)`; end
      end
    end
  end
end


class Runtime
  attr_reader :scene, :renderer, :camera, :engine, :gui, :settings

  def initialize
    @settings = GeneralSettings.new
    @gui = nil

    @accordion = Accordion.new(:editors)
    @accordion.on_open do |element|
      id = `$('.editor', element).attr('id')`
      editor = {
          'geometryShader' => @geometry_editor,
          'fragmentShader' => @fragment_editor,
          'pixelShader' => @pixel_editor
      }[id]
      editor.resize true unless editor.nil?
    end
    Element.find("#useGeometryShader").on(:click) do |evt|
      @engine.use_geometry_shader = `evt.native.currentTarget.selected`
      rebuild
    end
    Element.find("#usePixelShader").on(:click) do |evt|
      @engine.use_pixel_shader = `evt.native.currentTarget.selected`
      rebuild
    end

    @geometry_editor = ACE::Editor.new "geometryShader"
    @fragment_editor = ACE::Editor.new "fragmentShader"
    @pixel_editor = ACE::Editor.new "pixelShader"
    [ @geometry_editor, @fragment_editor, @pixel_editor ].each  do |editor|
      editor.theme = "ace/theme/monokai"
      editor.mode = "ace/mode/glsl"
    end

    @actors = nil
    @camera = THREE::Camera.new(60, `window.innerWidth / window.innerHeight`, 1, 1000)
    @camera.set_position :x => -300, :y => 300, :z => 300

    @scene = THREE::Scene.new
    setup_scene

    @renderer = THREE::WebGLRenderer.new
    @renderer.set_clear_color( 0xcccccc, 1 )
    Window.on(:resize) { on_resize }

    @engine = NLSE::Target::Ruby::Engine.new
    @engine.profile = NLSE::Target::Ruby::DeviceProfile.new
    normal = NLSE::Target::Ruby::Runtime::Vec3.new(0, 1, 0)
    @engine.arrangement = (0...10).map {|x| (0...10).map {|y| NLSE::Target::Ruby::Runtime::Vec3.new(x, 0, y) } }.flatten
      .map {|e| [e * 20, normal] }
  end

  def start
    on_resize
    update = proc do
      animate
      `requestAnimationFrame(function() { update.call() })`
    end
    update.call
  end

  def render
    @renderer.render(@scene, @camera) unless @renderer.nil?
  end

  def animate
    update_shader_computation
    `self.controls.update()`
    render
  end

  def rebuild
    reload_shaders do
      rebuild_scene if settings.initGeometry
      rebuild_gui
    end
  end

  def reload_shaders(&block)
    do_pixel = lambda do
      if @engine.use_pixel_shader
        reload_shader(:pixel) { yield if block_given? }
      elsif block_given?
        yield
      end
    end
    do_geom = lambda do
      if @engine.use_geometry_shader
        reload_shader(:geometry) { do_pixel.call }
      else
        do_pixel.call
      end
    end

    reload_shader(:fragment) { do_geom.call }
  end

  def update_shader_computation
    unless @actors.nil?
      geometry, fragment, pixel = @engine.execute
      geometry.each_with_index {|pos, idx|
        @actors[idx].set_position pos.first, pos.last if settings.updateGeometry
        @actors[idx].set_height fragment[idx].first unless fragment[idx].nil?
        @actors[idx].set_color pixel[idx].first unless pixel[idx].nil?
      }
    end
  end

  def rebuild_scene
    @scene = THREE::Scene.new
    setup_scene

    @engine.reset_time
    @actors = @engine.arrangement.map {|frag| pos,norm=frag; THREE::ShapeBlock.new(pos, norm) }
    @actors.each {|actor| @scene.add(actor.mesh) }
    render
  end

  def reload_shader(type, &block)
    name = "SH#{Time.now().to_i}#{rand(1000)}"
    editor = {
      :geometry => @geometry_editor,
      :fragment => @fragment_editor,
      :pixel    => @pixel_editor
    }[type]

    code = editor.value
    HTTP.post("/compile/#{type}/#{name}", :payload => { :code => code } ) do |response|
      editor.clear_markers
      editor.clear_annotations
      if response.ok?
        new_class = response.body
        `eval(new_class)`

        shader = `eval("Opal." + name + ".$new()")`
        if type == :geometry
          state = @engine.geometry_shader.shader.uniform_state rescue {}
          @engine.geometry_shader = NLSE::Target::Ruby::GeometryShader.new(shader)
          @engine.geometry_shader.shader.bind_uniform(state)
        elsif type == :fragment
          state = @engine.fragment_shader.shader.uniform_state rescue {}
          @engine.fragment_shader = NLSE::Target::Ruby::FragmentShader.new(shader)
          @engine.fragment_shader.shader.bind_uniform(state)
        elsif type == :pixel
          state = @engine.pixel_shader.shader.uniform_state rescue {}
          @engine.pixel_shader = NLSE::Target::Ruby::PixelShader.new(shader)
          @engine.pixel_shader.shader.bind_uniform(state)
        end

        yield if block_given?
      else
        status = response.json
        message = "#{status["error"]} error: #{status["reason"]}"
        editor.add_maker status["where"]["line"], "error"
        editor.add_annotation status["where"]["line"] - 1, "error", message
      end
    end
  end

  def rebuild_gui
    gui.destroy unless gui.nil?

    @gui = DatGUI::GUI.new self
    general = @gui.add_folder "General"
    general.add settings, "initGeometry"
    general.add settings, "updateGeometry"
    general.add settings, "updateColor"
    general.add settings, "fragCount"
    general.open

    unless @engine.nil? or @engine.geometry_shader.nil? or @engine.geometry_shader.custom_uniforms.empty?
      geom = @gui.add_folder "Geometry Uniforms"
      @engine.geometry_shader.custom_uniforms.each {|uniform|
        geom.add @engine.geometry_shader.shader, uniform
      }
      geom.open
    end

    unless @engine.nil? or @engine.fragment_shader.nil? or @engine.fragment_shader.custom_uniforms.empty?
      fragment = @gui.add_folder "Fragment Uniforms"
      @engine.fragment_shader.custom_uniforms.each {|uniform|
        fragment.add @engine.fragment_shader.shader, uniform
      }
      fragment.open
    end

    unless @engine.nil? or @engine.pixel_shader.nil? or @engine.pixel_shader.custom_uniforms.empty?
      pixel = @gui.add_folder "Pixel Uniforms"
      @engine.pixel_shader.custom_uniforms.each {|uniform|
        pixel.add @engine.pixel_shader.shader, uniform
      }
      pixel.open
    end

    view = @gui.add_folder "View"
    view.add @camera, "$view_front"
    view.open
  end

  private
  def setup_scene
    # workaround to keep the correct context
    render = proc { self.render }

%x{
    var controls = new THREE.OrbitControls( self.camera.camera );
    self.controls = controls;
    controls.enabled = false;
    controls.addEventListener( 'change', function() { render.call() } );
    $('#canvasContainer').mouseover(function() { controls.enabled = true; });
    $('#canvasContainer').mouseout(function() { controls.enabled = false; });

    var scene = self.scene.scene;

    // lights
    light = new THREE.DirectionalLight( 0xffffff );
    light.position.set( 1, 1, 1 );
    scene.add( light );

    light = new THREE.DirectionalLight( 0x002288 );
    light.position.set( -1, -1, -1 );
    scene.add( light );

    light = new THREE.AmbientLight( 0x222222 );
    scene.add( light );
}
  end

  def on_resize
    width = Element.find('#canvasContainer').width
    height = `window.innerHeight`
    @camera.aspect = width / height
    @renderer.set_size(width, height)

    @accordion.height = `window.innerHeight` - Element.find(".toolbar").height
    [ @geometry_editor, @fragment_editor, @pixel_editor ].each {|editor| editor.resize true }
    Element.find('body').css(:height => height)
    render
  end

end

class GeneralSettings
  attr_accessor :initGeometry, :updateGeometry, :updateColor, :fragCount

  def initialize(runtime)
    @runtime = runtime

    @initGeometry = true
    @updateGeometry = false
    @updateColor = true
    @fragCount = 64
  end

end

Document.ready? do
  runtime = Runtime.new
  Element.find('#canvasContainer') << runtime.renderer.dom_element

  Element.find('#runButton').on(:click) do runtime.rebuild; end
  runtime.rebuild

  Element.find("body").on(:keypress) do |evt|
    if evt.key_code == 13 and `evt.native.shiftKey`
      evt.prevent_default
      runtime.rebuild
    end
  end

  runtime.start
  `window.runtime = runtime`
end

