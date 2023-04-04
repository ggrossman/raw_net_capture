# encoding: utf-8

module Net
  class BufferedIO
    private
    alias_method :orig_rbuf_consume, :rbuf_consume
    alias_method :orig_write0, :write0

    def rbuf_consume(len = nil)
      return orig_rbuf_consume(len) unless @debug_output

      begin
        saved_debug_output = @debug_output
        @debug_output = nil
        str = orig_rbuf_consume(len)
      ensure
        @debug_output = saved_debug_output
      end

      @debug_output << %Q[-> #{str.dump}\n]
      @debug_output.received(str) if @debug_output.respond_to?(:received)
      str
    end

    def write0(*strs)
      return orig_write0(*strs) unless @debug_output

      begin
        saved_debug_output = @debug_output
        @debug_output = nil
        ret = orig_write0(*strs)
      ensure
        @debug_output = saved_debug_output
      end

      strs.each do |str|
        @debug_output << str.dump
        @debug_output.sent(str) if @debug_output.respond_to?(:sent)
      end

      ret
    end
  end
end
