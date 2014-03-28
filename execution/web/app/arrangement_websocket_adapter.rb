require 'target.ruby'
require 'delegate'

class ArrangementWebsocketAdapter < SimpleDelegator

  def initialize(url)
    super([])
    @url = url
    @connection = nil
    @on_data_received = nil
  end

  def restart_connection
    # `self.connection.close()` unless @connection = nil
    @connection = `new WebSocket(self.url)`
    %x{
    self.connection.binaryType = 'arraybuffer';
    self.connection.onmessage = function(evt) { #{on_message(`evt`)} }
    }
  end

  def shutdown
    `self.connection.close()`
  end

  def on_data_received(&block)
    @on_data_received = block
  end

  def respond_to?(name)
    if name == :on_ready or name == :shutdown
      true
    else
      super(name)
    end
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

end