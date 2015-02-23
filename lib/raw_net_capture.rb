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
  attr_reader :raw_received, :raw_sent, :transactions

  def initialize
    super
    reset
  end

  def received(data)
    @raw_received << data
  end

  def sent(data)
    # when there are multiple requests on the same connection, E.g. redirection, we want the last one.
    if raw_received.length > 0
      _transactions << Transaction.new(self)
      reset
    end

    @raw_sent << data
  end

  def transactions
    _transactions.tap do |transactions|
      if raw_received.length > 0
        transactions << Transaction.new(self)
      end
    end
  end

  private

  def _transactions
    @transactions ||= []
  end

  def reset
    @raw_received = StringIO.new
    @raw_sent = StringIO.new
  end

  class Transaction
    HEADER_BODY_SEPARATOR = "\r\n\r\n"
    attr_reader :response, :request

    def initialize(capture)
      @request = Request.new(capture)
      @response = Response.new(capture)
    end

    class ExchangePart
      attr_reader :headers, :body

      def initialize(capture)
        raw_string = capture.send(method).string

        @headers, _, @body = raw_string.partition(HEADER_BODY_SEPARATOR).map { |p| p.empty? ? nil : p  }
      end
    end

    class Response < ExchangePart
      def method
        'raw_received'
      end
    end

    class Request < ExchangePart
      def method
        'raw_sent'
      end
    end
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
