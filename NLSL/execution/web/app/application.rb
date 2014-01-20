require 'opal'
require 'opal-jquery'
require 'THREE'
require 'DatGUI'
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

    @leds = nil
    @camera = THREE::Camera.new(60, `window.innerWidth / window.innerHeight`, 1, 500)
    @camera.set_z 300

    @scene = THREE::Scene.new
    setup_scene

    @renderer = THREE::WebGLRenderer.new
    @renderer.set_clear_color( `self.scene.scene.fog.color`, 1 )
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
    render
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
    editorID = "#{type}Shader"
    code = ""
    %x{
    var editor = ace.edit(editorID);
    code = editor.getSession().getValue();
    }
    HTTP.post("/compile/#{type}/#{name}", :payload => { :code => code } ) do |response|
      if response.ok?
        new_class = response.body
        `eval(new_class)`

        shader = `eval("Opal." + name + ".$new()")`
        if type == :geometry
          @engine.geometry_shader = NLSE::Target::Ruby::GeometryShader.new(shader)
        elsif type == :color
          @engine.color_shader = NLSE::Target::Ruby::ColorShader.new(shader)
        end

        yield if block_given?
      else
        status = response.json
        message = "#{status["error"]} error: #{status["reason"]}"
        `alert(message)`
      end
    end
  end

  def rebuild_gui
    gui.destroy unless gui.nil?

    @gui = DatGUI::GUI.new
    general = @gui.add_folder "General"
    general.add settings, "updateGeometry"
    general.add settings, "updateColor"

    unless @engine.nil? or @engine.geometry_shader.nil? or @engine.geometry_shader.custom_uniforms.empty?
      geom = @gui.add_folder "Geometry Uniforms"
      @engine.geometry_shader.custom_uniforms.each {|uniform|
        geom.add @engine.geometry_shader.shader, uniform
      }
    end

    unless @engine.nil? or @engine.color_shader.nil? or @engine.color_shader.custom_uniforms.empty?
      color = @gui.add_folder "Color Uniforms"
      @engine.color_shader.custom_uniforms.each {|uniform|
        color.add @engine.color_shader.shader, uniform
      }
    end
  end

  private
  def setup_scene
    # workaround to keep the correct context
    render = proc { self.render }

%x{
    controls = new THREE.OrbitControls( self.camera.camera );
    controls.addEventListener( 'change', function() { render.call() } );

    var scene = self.scene.scene;
    scene.fog = new THREE.FogExp2( 0xcccccc, 0.002 );

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
    width = `window.innerWidth`
    height = `window.innerHeight`
    @camera.aspect = width / height
    @renderer.set_size(width, height)

    render
  end

end

class GeneralSettings
  attr_accessor :updateGeometry, :updateColor

  def initialize
    @updateGeometry = false
    @updateColor = true
  end

end

Document.ready? do
  runtime = Runtime.new
  Element.find('body') << runtime.renderer.dom_element

  reload = proc { runtime.reload_shaders do runtime.rebuild_scene; runtime.rebuild_gui; end }
  Element.find('#runButton').on(:click) do reload.call; end
  reload.call

  runtime.rebuild_gui

  runtime.start
end

