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

  private

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

  def received(data)
    @raw_received << data
  end

  def sent(data)
    if raw_received.length > 0
      reset
    end

    @raw_sent << data
  end

  def headers
    separator = "\r\n\r\n"
    raw_string = @raw_received.string

    if headers_end_index = raw_string.index(separator)
      raw_string[0...(headers_end_index + separator.length)]
    else
      raw_string
    end
  end

  private

  def reset
    @raw_received = StringIO.new
    @raw_sent = StringIO.new
  end
end

module Net
  class BufferedIO
    private

    def rbuf_consume(len)
      str = @rbuf.slice!(0, len)
      if @debug_output
        @debug_output << %Q[-> #{str.dump}\n]
        @debug_output.received(str) if @debug_output.respond_to?(:received)
      end
      str
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
