# encoding: utf-8

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
        @body ||= parts[2]
      end

      def headers
        @headers ||= parts[0]
      end

      def raw
        @raw ||= raw_io.string
      end

      private

      attr_reader :raw_io

      # headers and body
      def parts
        @parts ||= raw.partition(HEADER_BODY_SEPARATOR).map do |part|
          part.empty? ? nil : part
        end
      end
    end

    class Response < Part; end
    class Request < Part; end
  end
end
