# encoding: utf-8

class RawNetCapture < StringIO
  attr_reader :raw_traffic

  def initialize
    super
    reset
  end

  def received(data)
    @raw_traffic << [:received, data]
  end

  def sent(data)
    @raw_traffic << [:sent, data]
  end

  def reset
    @raw_traffic = []
  end
end

class RawHTTPCapture < StringIO
  attr_reader :raw_received, :raw_sent

  def initialize
    super
    reset
  end

  def reset
    @raw_received = StringIO.new
    @raw_sent = StringIO.new
  end

  def received(data)
    @raw_received << data
  end

  def sent(data)
    @raw_sent << data
  end

  def headers_only!
    if headers_end_index = @raw_received.string.index("\r\n\r\n")
      @raw_received.truncate(headers_end_index+2)
    end
    !!headers_end_index
  end
end

module Net
  class BufferedIO
    private

    def rbuf_consume(len)
      s = @rbuf.slice!(0, len)
      if @debug_output
        @debug_output << %Q[-> #{s.dump}\n]
        @debug_output.received(s) if @debug_output.respond_to?(:received)
      end
      s
    end

    def write0(str)
      if @debug_output
        @debug_output << str.dump
        @debug_output.sent(str) if @debug_output.respond_to?(:sent)
      end
      len = @io.write(str)
      @written_bytes += len
      len
    end
  end
end
