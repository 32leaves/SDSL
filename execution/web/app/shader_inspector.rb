require 'opal-jquery'

class ShaderInspector

  def initialize(engine)
    @engine = engine
    @element = Element.find("#rt_inspector")
    @element.hide

    Document.ready? do
      Element.find("#rt_inspector .close").on(:click) do @element.hide; end
      Element.find(".inspect").on(:click) do inspect_active_editor; end
    end
  end

  def inspect_active_editor
    editor_id = Element.find(".active .editor").attr('id')
    `if(editor_id == undefined) return;`

    table = @element.find("table")
    table.empty
    shader = case editor_id
      when 'geometryShader'
        @engine.geometry_shader
      when 'fragmentShader'
        @engine.fragment_shader
      when 'pixelShader'
        @engine.pixel_shader
    end
    shader.shader.known_uniforms.each do |name|
      value = shader.shader.send(name)
      value = value.to_html rescue value.to_s
      table.append "<tr><td class=\"name\">#{name}</td><td>#{value}</td></tr>"
    end

    li_element = Element.find("##{editor_id}").closest("li")
    @element.css :top => `li_element.offset().top`
    @element.show
  end

end