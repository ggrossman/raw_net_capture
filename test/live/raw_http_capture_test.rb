require File.expand_path '../../helper', __FILE__

class RawHTTPCaptureTest < MiniTest::Test
  describe RawHTTPCapture do
    let(:capture) { RawHTTPCapture.new }

    describe "with get to example.net" do
      before do
        uri = URI.parse("https://example.net/")
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true
        @http.set_debug_output capture
        @http.get(uri.request_uri)
      end

      it "captures raw HTTP request and response" do
        assert_match(/\AGET \/ HTTP\/1\.1.*Host: example\.net.*\z/m, capture.transactions.first.request.headers)
        assert_match(/\AHTTP\/1\.1 200 OK.*\z/m, capture.transactions.first.response.headers)
      end

      it "created one transaction" do
        assert_equal 1, capture.transactions.size
      end

      describe "and another get with a query string" do
        before do
          uri = URI.parse("https://example.net/?test")
          @http.get(uri.request_uri)
        end

        it "captures the last request when multiple are invoked" do
          assert_match(/\AGET \/\?test HTTP\/1\.1.*Host: example\.net.*\z/m, capture.transactions.last.request.headers)
          assert_match(/\AHTTP\/1\.1 200 OK.*\z/m, capture.transactions.last.response.headers)
        end

        it "creates 2 transactions" do
          assert_equal 2, capture.transactions.size
        end
      end
    end
  end
end
