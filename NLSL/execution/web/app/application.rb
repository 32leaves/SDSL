require 'opal'
require 'opal-jquery'
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
      end
    end
  end
end


class Runtime
  attr_reader :scene, :renderer, :camera, :engine, :gui, :settings

  def initialize
    @settings = GeneralSettings.new
    @gui = nil

    @geometry_editor = ACE::Editor.new "geometryShader"
    @color_editor = ACE::Editor.new "colorShader"
    [ @geometry_editor, @color_editor ].each  do |editor|
      editor.theme = "ace/theme/monokai"
      editor.mode = "ace/mode/glsl"
    end

    @leds = nil
    @camera = THREE::Camera.new(60, `window.innerWidth / window.innerHeight`, 1, 1000)
    @camera.set_position :z => 300

    @scene = THREE::Scene.new
    setup_scene

    @renderer = THREE::WebGLRenderer.new
    @renderer.set_clear_color( 0xcccccc, 1 )
    Window.on(:resize) do on_resize; end

    @engine = NLSE::Target::Ruby::Engine.new
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
    reload_shader(:geometry) { reload_shader(:color) { yield if block_given? } }
  end

  def update_shader_computation
    unless @leds.nil?
      geometry, color = @engine.execute
      geometry.each_with_index {|pos, idx|
        @leds[idx].set_position pos if settings.updateGeometry
        @leds[idx].set_color color[idx] if settings.updateColor
      }
      color
    end
  end

  def rebuild_scene
    @scene = THREE::Scene.new
    setup_scene

    @engine.reset_time
    @leds = @engine.compute_geometry.map {|pos| THREE::LED.new(pos) }
    @leds.each {|led| @scene.add(led.mesh) }
    render
  end

  def reload_shader(type, &block)
    name = "SH#{Time.now().to_i}#{rand(1000)}"
    editor = type == :geometry ? @geometry_editor : @color_editor
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
        elsif type == :color
          state = @engine.color_shader.shader.uniform_state rescue {}
          @engine.color_shader = NLSE::Target::Ruby::ColorShader.new(shader)
          @engine.color_shader.shader.bind_uniform(state)
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
    general.open

    unless @engine.nil? or @engine.geometry_shader.nil? or @engine.geometry_shader.custom_uniforms.empty?
      geom = @gui.add_folder "Geometry Uniforms"
      @engine.geometry_shader.custom_uniforms.each {|uniform|
        geom.add @engine.geometry_shader.shader, uniform
      }
      geom.open
    end

    unless @engine.nil? or @engine.color_shader.nil? or @engine.color_shader.custom_uniforms.empty?
      color = @gui.add_folder "Color Uniforms"
      @engine.color_shader.custom_uniforms.each {|uniform|
        color.add @engine.color_shader.shader, uniform
      }
      color.open
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

    Element.find('body').css(:height => height)
    render
  end

end

class GeneralSettings
  attr_accessor :initGeometry, :updateGeometry, :updateColor

  def initialize(runtime)
    @runtime = runtime

    @initGeometry = true
    @updateGeometry = false
    @updateColor = true
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
      reload.rebuild
    end
  end

  runtime.start
end

