require 'target.ruby'

class SamplerWebsocketAdapter

  def initialize(dimension_count)
    @data = nil
    @dimension_count = dimension_count
    @type_constructor = [
      nil,
      lambda {|value| value },
      NLSE::Target::Ruby::Runtime::Vec2.method(:new),
      NLSE::Target::Ruby::Runtime::Vec3.method(:new),
      NLSE::Target::Ruby::Runtime::Vec4.method(:new),
    ][dimension_count]
    @url = ""
    @connection = nil
  end

  def restart_connection
   # `self.connection.close()` unless @connection = nil
    @connection = `new WebSocket(self.url)`
    %x{
    self.connection.binaryType = 'arraybuffer';
    self.connection.onmessage = function(evt) { #{on_message(`evt`)} }
    }
  end

  def is_a?(klass)
    if klass == SamplerWebsocketAdapter
      true
    else
      false
    end
  end

  def [](idx)
    args = (0...@dimension_count).map {|j| `self.data[(self.dimension_count * idx) + j]` }
    @type_constructor.call(*args)
  end

  def comp(idx, dim)
    dim |= 0
    `self.data[self.dimension_count * idx + dim]`
  end

  private
  def on_message(evt)
    @data = `new Uint8Array(evt.data)`
  end

end