require 'target.ruby'
require 'delegate'

class ArrangementWebsocketAdapter < SimpleDelegator

  def initialize(url)
    super([])
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

  def [](idx)
    @data[idx]
  end

  def each(&block)
    @data.each block
  end

  private
  def on_message(evt)
    data = `new Float32Array(evt.data)`

    result = (0...`data.length`).map do |idx|
      position = (0...3).map {|j| `data[(6 * idx) + j]` }
      normal   = (3...6).map {|j| `data[(6 * idx) + j]` }
      [ NLSE::Target::Ruby::Runtime::Vec3.new(*position), NLSE::Target::Ruby::Runtime::Vec3.new(*normal) ]
    end
    __setobj__(result)
  end

end