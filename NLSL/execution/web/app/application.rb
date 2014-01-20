require 'opal'
require 'opal-jquery'
require 'THREE'
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
  attr_reader :scene, :renderer, :camera, :engine

  def initialize
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
        #@leds[idx].set_position pos
        @leds[idx].set_color color[idx]
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
      new_class = response.body
      `eval(new_class)`

      shader = `eval("Opal." + name + ".$new()")`
      if type == :geometry
        @engine.geometry_shader = NLSE::Target::Ruby::GeometryShader.new(shader)
      elsif type == :color
        @engine.color_shader = NLSE::Target::Ruby::ColorShader.new(shader)
        shader.bind_uniform({:bluetone => 0.5})
      end

      yield if block_given?
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

Document.ready? do
  runtime = Runtime.new
  Element.find('body') << runtime.renderer.dom_element

  reload = proc { runtime.reload_shaders do runtime.rebuild_scene; end }
  Element.find('#runButton').on(:click) do reload.call; end
  reload.call

  runtime.start
end

