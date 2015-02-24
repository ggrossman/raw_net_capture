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
  attr_reader :transactions

  def initialize
    super
    reset
  end

  def received(data)
    @raw_received << data
  end

  def sent(data)
    # when there are multiple requests on the same connection, E.g. redirection, we want the last one.
    if @raw_received.length > 0
      reset
    end

    @raw_sent << data
  end

  def transactions
    @transactions ||= []
  end

  private

  attr_reader :raw_sent, :raw_received

  def reset
    @raw_received = StringIO.new
    @raw_sent = StringIO.new
    transactions << Transaction.new(self)
  end

  class Transaction
    HEADER_BODY_SEPARATOR = "\r\n\r\n"
    attr_reader :response, :request

    def initialize(capture)
      @request = Request.new(capture.send(:raw_sent))
      @response = Response.new(capture.send(:raw_received))
    end

    class Part
      attr_reader :headers, :body, :raw

      def initialize(raw_io)
        @raw_io = raw_io
      end

      def body
        @body ||= unless calculated_parts?
          calculate_parts
          body
        end
      end

      def headers
        @headers ||= unless calculated_parts?
          calculate_parts
          headers
        end
      end

      def raw
        @raw ||= raw_io.string
      end

      private

      attr_reader :raw_io

      def calculate_parts
        @headers, _, @body = raw.partition(HEADER_BODY_SEPARATOR).map do |part|
          part.empty? ? nil : part
        end

        @calculated_parts = true
      end

      def calculated_parts?
        !!@calculated_parts
      end
    end

    class Response < Part; end
    class Request < Part; end
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
