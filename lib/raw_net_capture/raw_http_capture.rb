# encoding: utf-8

class RawHTTPCapture < StringIO
  def initialize
    super
    reset
  end

  def received(data)
    transactions.last.response.raw_io << data
  end

  def sent(data)
    # when there are multiple requests on the same connection, E.g. redirection, we want the last one.
    if transactions.last.response.raw_io.length > 0
      reset
    end

    transactions.last.request.raw_io << data
  end

  def transactions
    @transactions ||= []
  end

  private

  def reset
    transactions << Transaction.new
  end

  class Transaction
    attr_reader :response, :request

    def initialize
      @request = Request.new
      @response = Response.new
    end

    class Part
      def body
        @body ||= partitions[2]
      end

      def headers
        @headers ||= partitions[0]
      end

      def raw_io
        @raw_io ||= StringIO.new
      end

      def raw
        @raw ||= raw_io.string
      end

      private

      # headers and body
      def partitions
        @partitions ||= raw.partition("\r\n\r\n").map do |part|
          part.empty? ? nil : part
        end
      end
    end

    class Response < Part; end
    class Request < Part; end
  end
end
