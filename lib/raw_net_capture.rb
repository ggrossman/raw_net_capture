# encoding: utf-8

class RawNetCapture < StringIO
  def raw_received
    @raw_received ||= StringIO.new
  end

  def raw_sent
    @raw_sent ||= StringIO.new
  end  
end

module Net
  class BufferedIO
    private

    def rbuf_consume(len)
      s = @rbuf.slice!(0, len)
      if @debug_output
        @debug_output << %Q[-> #{s.dump}\n]
        @debug_output.raw_received << s if @debug_output.is_a?(RawNetCapture)
      end
      s
    end

    def write0(str)
      if @debug_output
        @debug_output << str.dump
        @debug_output.raw_sent << str if @debug_output.is_a?(RawNetCapture)
      end
      len = @io.write(str)
      @written_bytes += len
      len
    end
  end
end
