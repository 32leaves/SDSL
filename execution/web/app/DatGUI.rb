module DatGUI

  class Folder

    def initialize(parent)
      @parent = parent
    end

    def add_folder(label)
      folder = `self.parent.addFolder(label)`
      Folder.new folder
    end

    def open
      `self.parent.open()`
    end

    def close
      `self.parent.close()`
    end

    def add(ref, id, constraint = nil)
      if constraint.nil?
        Field.new `self.parent.add(ref, id)`
      else
        Field.new `self.parent.add(ref, id, constraint)`
      end
    end

  end

  class Field
    attr_accessor :controller

    def initialize(controller)
      @controller = controller
    end

    def on_finish(&block)
      `self.controller.onFinishChange(function() { #{block.call} })`
    end

    def name=(value)
      `self.controller.name(value)`
    end

  end


  class GUI < Folder

    def initialize(auto_place = true)
      super `new dat.GUI({ autoPlace: auto_place })`
    end

    def dom_element
      `self.parent.domElement`
    end

    def destroy
      `self.parent.destroy()`
    end

  end

end