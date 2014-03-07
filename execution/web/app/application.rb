require 'opal'
require 'opal-jquery'
require 'native'
require 'accordion'
require 'shader_inspector'
require 'THREE'
require 'DatGUI'
require 'ACE'
require 'sampler_websocket_adapter'
require 'js_zip'
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
  attr_reader :scene, :renderer, :camera, :engine, :gui, :settings, :inspector

  def initialize
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
    Element.find(`window`).on(:resize) { on_resize }

    @engine = NLSE::Target::Ruby::Engine.new
    @engine.profile = NLSE::Target::Ruby::DeviceProfile.new
    normal = NLSE::Target::Ruby::Runtime::Vec3.new(0, 1, 0)
    @engine.arrangement = (0...10).map {|x| (0...10).map {|y| NLSE::Target::Ruby::Runtime::Vec3.new(x, 0, y) } }.flatten
      .map {|e| [e * 20, normal] }


    @inspector = ShaderInspector.new @engine
  end

  def get_shader_code
    [ @geometry_editor, @fragment_editor, @pixel_editor ].map {|e| e.value }
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
      rebuild_scene
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
    errorbox = Element.find("#rt_errorbox")

    begin
      geometry, fragment, pixel = @engine.execute
      geometry.each_with_index {|pos, idx|
        #@actors[idx].set_position pos.first, pos.last
        @actors[idx].set_height fragment[idx].first unless fragment[idx].nil?
        @actors[idx].set_color pixel[idx].first unless pixel[idx].nil?
      }

      errorbox.hide
    rescue => e
      shader_type = e.class.name.split("::").last.gsub("ShaderRuntimeException", "").downcase
      editor_id = "#{shader_type}Shader"

      li_element = Element.find("##{editor_id}").closest("li")
      errorbox.css :top => `li_element.offset().top`
      errorbox.find(".text").text e
      errorbox.show

      #Element.find("##{editor_id}").closest("li").add_class :shader_rt_error
    end unless @actors.nil?
  end

  def rebuild_scene
    @scene = THREE::Scene.new
    setup_scene

    @engine.reset_time
    offset = @engine.fragment_resolution * -0.5
    actor_arrangement = @engine.arrangement.map {|e| p,n=e; [p + offset, n] }
    @actors = actor_arrangement.map {|frag| pos,norm=frag; THREE::ShapeBlock.new(pos, norm) }
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
    `console.log(code)`
    HTTP.post("/compile/#{type}/#{name}", :payload => { :code => code } ) do |response|
      editor.clear_markers
      editor.clear_annotations
      if response.ok?
        new_class = response.body
        `eval(new_class)`

        shader = `eval("Opal." + name + ".$new()")`
        state = @engine.send("#{type}_shader".to_s).shader.uniform_state rescue {}
        new_wrapper = {
            :geometry => NLSE::Target::Ruby::GeometryShader,
            :fragment => NLSE::Target::Ruby::FragmentShader,
            :pixel    => NLSE::Target::Ruby::PixelShader
        }[type].new(shader)
        @engine.send("#{type}_shader=".to_s, new_wrapper)
        shader.bind_uniform(state)
        shader.bind_uniform(shader.known_uniforms
                            .select {|k| shader.uniform_type(k).to_s[0...7] == "sampler" }
                            .reject {|k| shader.send(k).is_a? SamplerWebsocketAdapter }
                            .inject({}) do |m, k|

          dim = shader.uniform_type(k).to_s[-2...-1].to_i
          m[k] = SamplerWebsocketAdapter.new dim
          m
        end)

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
    res = @gui.add_folder "Pixel Resolution"
    res.add @engine.profile.pixel_resolution, "x"
    res.add @engine.profile.pixel_resolution, "y"
    res.open

    unless @engine.nil?
      [ @engine.geometry_shader, @engine.fragment_shader, @engine.pixel_shader ]
        .compact.reject {|shader| shader.custom_uniforms.empty?  }.each do |shader|

        folder = @gui.add_folder shader.class.name.split("::").last
        shader.custom_uniforms.each do |uniform|
          uniform_type = shader.shader.uniform_type(uniform)

          if uniform_type == :float or uniform_type == :int
            folder.add shader.shader, uniform
          elsif [ :sampler1D, :sampler2D, :sampler3D, :sampler4D ].include?(uniform_type)
            adapter = shader.shader.send(uniform)
            controller = folder.add adapter, "url"
            controller.name = uniform
            controller.on_finish { adapter.restart_connection }
          end
        end
        folder.open
      end
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

Document.ready? do
  runtime = Runtime.new
  Element.find('#canvasContainer') << runtime.renderer.dom_element

  Element.find('.inspect').on(:click) do
    geom, frag, pixel = runtime.get_shader_code

    zip = JSZip::ZipFile.new
    zip.file("geometry.sdsl", geom)
    zip.file("fragment.sdsl", frag)
    zip.file("pixel.sdsl", pixel)
    content = zip.to_base64

    `location.href="data:application/zip;base64,"+content`
  end

  Element.find('#runButton').on(:click) do runtime.rebuild; end
  runtime.rebuild

  Element.find("body").on(:keypress) do |evt|
    if `evt.keyCode == 13 && evt.shiftKey`
      evt.prevent_default
      runtime.rebuild
    elsif `evt.keyCode == 9 && evt.ctrlKey`
      runtime.inspector.inspect_active_editor
    end
  end

  runtime.start
  `window.runtime = runtime`
end

