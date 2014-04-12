require 'target.ruby'
require 'delegate'

class ArrangementWebsocketAdapter < SimpleDelegator

  def initialize(url)
    super([])
    @url = url
    @connection = nil
    @connected = false
    @on_data_received = nil

    @buffer_initialized = false
    @buffer = nil
    @view = nil
  end

  def restart_connection
    # `self.connection.close()` unless @connection = nil
    @connection = `new WebSocket(self.url)`
    %x{
    self.connection.binaryType = 'arraybuffer';
    self.connection.onmessage = function(evt) { #{on_message(`evt`)} }
    self.connection.onopen = function(evt) { self.connected = true; }
    self.connection.onclose = function(evt) { self.connected = false; }
    }
  end

  def dump_shader_computation(fragment, pixel)
    return unless @connected
    return if `self.view == undefined`

    has_pixels = fragment.length == pixel.length
    fragmentCount = fragment.length
    pixelCount = (has_pixels ? pixel.first.length : 0)
    length = fragment.length + (fragment.length * (3 * pixelCount))
    init_buffer(length)
    i = 0
    j = 0
    %x{
      for(var i = 0; i < fragmentCount; i++) {
          var offset = i * (1 + 3 * pixelCount);

          self.view[offset + 0] = #{fragment[i][0]};
          for(j = 0; j < pixelCount; j++) {
            self.view[offset + ((1 + j) * 3) + 0] = #{pixel[i][j].x};
            self.view[offset + ((1 + j) * 3) + 1] = #{pixel[i][j].y};
            self.view[offset + ((1 + j) * 3) + 2] = #{pixel[i][j].z};
          }
        }
      }

    `self.connection.send(self.view)`
  end

  def shutdown
    `self.connection.close()`
  end

  def on_data_received(&block)
    @on_data_received = block
  end

  def respond_to?(name)
    name == :on_ready or name == :shutdown or name == :dump_shader_computation or super(name)
  end

  def [](idx)
    @data[idx]
  end

  def each(&block)
    @data.each block
  end

  private
  def on_message(evt)
    data = `new Float32Array(evt.data)`

    result = (0...`data.length / 6`).map do |idx|
      position = (0...3).map {|j| `data[(6 * idx) + j]` }
      normal   = (3...6).map {|j| `data[(6 * idx) + j]` }
      [ NLSE::Target::Ruby::Runtime::Vec3.new(*position), NLSE::Target::Ruby::Runtime::Vec3.new(*normal) ]
    end
    __setobj__(result)

    unless @on_data_received.nil?
      @on_data_received.call(self)
    end
  end

  def init_buffer(length)
    return if @buffer_initialized and length == `view.length`

    @buffer = `new ArrayBuffer(length * 4)`
    @view = `new Float32Array(self.buffer)`
  end


end