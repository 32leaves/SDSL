require 'delegate'
require 'target.ruby'

class SamplerWebsocketAdapter < SimpleDelegator

  def initialize(dimension_count)
    super []

    @dimension_count = dimension_count
    @type_constructor = [
      lambda {|value| value },
      NLSE::Target::Ruby::Runtime::Vec2.method(:new),
      NLSE::Target::Ruby::Runtime::Vec3.method(:new),
      NLSE::Target::Ruby::Runtime::Vec4.method(:new),
    ][dimension_count]
    @url = ""
    @connection = nil
  end

  def restart_connection
    `self.connection.close()` unless @connection.nil?
    @connection = `new WebSocket(self.url)`
    %w{
    self.connection.binaryType = 'arraybuffer';
    self.connection.onmessage = self.$on_message;
    }
  end

  def is_a?(klass)
    if klass == SamplerWebsocketAdapter
      true
    else
      false
    end
  end

  private
  def on_message(evt)
    clear
    data = `new Float32Array(evt.data)`
    (0...(data.length / @dimension_count)).each do |i|
      offset = i * @dimension_count
      args = (0...@dimension_count).map {|j| `data[offset + j]` }
      self << @type_constructor.call(*args)
    end
  end

end