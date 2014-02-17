
module ACE

  class Editor

    def initialize(id)
      @editor = `ace.edit(id)`
      @range = `ace.require('ace/range').Range`
    end

    def theme=(name)
      `self.editor.setTheme(name)`
    end

    def mode=(name)
      `self.editor.getSession().setMode(name)`
    end

    def value
      `self.editor.getSession().getValue()`
    end

    def clear_markers
      %x{
        var markers = self.editor.session.getMarkers(true);
        for(var idx in markers)
          self.editor.session.removeMarker(idx);
      }
    end

    def add_maker(row, css_class)
      `self.editor.session.addMarker(new self.range(row - 1, 0, row, 0), css_class, "line", true)`
    end

    def clear_annotations
      `self.editor.session.clearAnnotations()`
    end

    def add_annotation(row, type, text)
      %x{
        annotations = self.editor.session.getAnnotations();
        annotations.push({ row: row, text: text, type: type })
        self.editor.session.setAnnotations(annotations)
      }
      nil
    end

    def resize(force)
      `self.editor.resize(force)`
    end

  end

end
