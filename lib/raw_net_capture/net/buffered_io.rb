# encoding: utf-8

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
