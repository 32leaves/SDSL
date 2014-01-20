module DatGUI

  class Folder

    def initialize(parent)
      @parent = parent
    end

    def add_folder(label)
      folder = `self.parent.addFolder(label)`
      Folder.new folder
    end

    def add(ref, id, constraint = nil)
      if constraint.nil?
        `self.parent.add(ref, id)`
      else
        `self.parent.add(ref, id, constraint)`
      end
    end

  end

  class Field

    def initialize(parent)
      @parent = parent
    end

    def min(val)
      `self.parent.min(val)`
    end

    def max(val)
      `self.parent.max(val)`
    end

    def step(val)
      `self.parent.step(val)`
    end

    def on_change(&block)
      `self.parent.onChange(block.$call)`
    end

    def on_finish_change(&block)
      `self.parent.onFinishChange(block.$call)`
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