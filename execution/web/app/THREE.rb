
module THREE

  class WebGLRenderer
    attr_reader :renderer

    def initialize
      @renderer = `new THREE.WebGLRenderer( { antialias: true } )`
    end

    def render(scene, camera)
      `self.renderer.render(scene.scene, camera.camera)`
    end

    def set_clear_color(color, b)
      `self.renderer.setClearColor( color, b )`
    end

    def set_size(width, height)
      `self.renderer.setSize(width, height)`
    end

    def dom_element
      `self.renderer.domElement`
    end

  end

  class Color
    attr_reader :color

    def initialize(vector)
      @color = `new THREE.Color()`
      `self.color.setRGB(vector.x, vector.y, vector.z)`
    end

  end

  class Camera
    attr_reader :camera

    def initialize(fov, aspectRatio, nearPlane, farPlane)
      @camera = `new THREE.PerspectiveCamera( fov, aspectRatio, nearPlane, farPlane );`
    end

    def view_front
      set_position(:x => 0, :y => 0, :z => 300)
    end

    def aspect=(value)
      `self.camera.aspect = value`
      `self.camera.updateProjectionMatrix()`
    end

    def set_position(args)
      x = args[:x]
      y = args[:z]
      z = args[:y]
      `self.camera.position.x = x` unless x.nil?
      `self.camera.position.y = y` unless y.nil?
      `self.camera.position.z = z` unless z.nil?
    end

  end

  class Scene
    attr_reader :scene

    def initialize
      @scene = `new THREE.Scene()`
    end

    def add(child)
      `self.scene.add(child)`
    end

    def clear
      `self.scene.children`.each {|child| `self.scene.remove(child)` }
    end

  end

  class ShapeBlock
    attr_reader :mesh

    def initialize(pos)
      @geometry = `new THREE.CubeGeometry( 10, 10, 10 )`
      @material =  `new THREE.MeshLambertMaterial( { color:0xffffff, shading: THREE.FlatShading } )`
      @mesh = `new THREE.Mesh( self.geometry, self.material )`
      `self.mesh.matrixAutoUpdate = false`

      set_position pos
      @mesh
    end

    def position
      @position
    end
    def set_position(pos)
      @position = pos

      `self.mesh.position.x = pos.x`
      `self.mesh.position.y = pos.z`
      `self.mesh.position.z = pos.y`
      `self.mesh.updateMatrix()`
    end

    def set_height(height)
      `self.mesh.scale.y = height`
      `self.mesh.position.y = (height * 10) / 2`
      `self.mesh.updateMatrix()`
    end

    def set_color(color)
      c = Color.new(color)
      `self.material.color = c.color`
    end
  end

  class LED
    attr_reader :mesh

    def initialize(pos)
      @geometry = `new THREE.SphereGeometry( 5, 10, 10 )`
      @material =  `new THREE.MeshLambertMaterial( { color:0xffffff, shading: THREE.FlatShading } )`
      @mesh = `new THREE.Mesh( self.geometry, self.material )`
      `self.mesh.matrixAutoUpdate = false`

      set_position pos
      @mesh
    end

    def position
      @position
    end
    def set_position(pos)
      @position = pos

      `self.mesh.position.x = pos.x`
      `self.mesh.position.y = pos.z`
      `self.mesh.position.z = pos.y`
      `self.mesh.updateMatrix()`
    end

    def set_color(color)
      c = Color.new(color)
      `self.material.color = c.color`
    end

  end

end