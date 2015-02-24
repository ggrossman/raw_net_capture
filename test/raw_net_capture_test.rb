# encoding: utf-8
require File.expand_path '../helper', __FILE__

class RawNetCaptureTest < MiniTest::Test
  describe "with get to google" do
    let(:http) do
      uri = URI.parse("https://www.google.com/")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.set_debug_output capture
      http.get(uri.request_uri)
      http
    end

    describe RawNetCapture do
      let(:capture) { RawNetCapture.new }

      before { http }

      it "captures raw HTTP request and response" do
        raw_sent = capture.raw_traffic.select { |x| x[0] == :sent }.map { |x| x[1] }.join
        raw_received = capture.raw_traffic.select { |x| x[0] == :received }.map { |x| x[1] }.join

        assert_match(/\AGET \/ HTTP\/1.1.*Host: www.google.com.*\z/m, raw_sent)
        assert_match(/\AHTTP\/1.1 200 OK.*\z/m, raw_received)
      end
    end

    describe RawHTTPCapture do
      let(:capture) { RawHTTPCapture.new }

      before { http }

      it "captures raw HTTP request and response" do
        assert_match(/\AGET \/ HTTP\/1.1.*Host: www.google.com.*\z/m, capture.transactions.first.request.headers)
        assert_match(/\AHTTP\/1.1 200 OK.*\z/m, capture.transactions.first.response.headers)
      end

      it "created one transaction" do
        assert_equal 1, capture.transactions.size
      end

      describe "and another get to google finance" do
        before do
          uri = URI.parse("https://www.google.com/finance?q=NYSE:ZEN")
          http.get(uri.request_uri)
        end

        it "captures the last request when multiple are invoked" do
          assert_match(/\AGET \/finance\?q=NYSE:ZEN HTTP\/1.1.*Host: www.google.com.*\z/m, capture.transactions.last.request.headers)
          assert_match(/\AHTTP\/1.1 200 OK.*\z/m, capture.transactions.last.response.headers)
        end

        it "creates 2 transactions" do
          assert_equal 2, capture.transactions.size
        end
      end

      describe "#transaction" do
        let(:transaction) { RawHTTPCapture::Transaction.new(capture) }

        describe "#response" do
          it "returns a response object" do
            assert_instance_of RawHTTPCapture::Transaction::Response, transaction.response
          end
        end

        describe "Response" do
          describe "when the raw_http_capture#raw_received#string returns a proper http response with a body" do
            before { capture.send(:raw_received).stubs(:string => "HTTP/1.1 200 OK\r\n\r\n{}") }

            describe "#body" do
              it "returns the body" do
                assert_equal "{}", transaction.response.body
              end
            end

            describe "#headers" do
              it "returns the headers" do
                assert_equal "HTTP/1.1 200 OK", transaction.response.headers
              end
            end

            describe "#raw" do
              it "returns the entire response" do
                assert_equal "HTTP/1.1 200 OK\r\n\r\n{}", transaction.response.raw
              end
            end
          end

          describe "when the raw_http_capture#raw_received#string returns a proper http response without a body" do
            before { capture.send(:raw_received).stubs(:string => "HTTP/1.1 200 OK\r\n\r\n") }

            describe "#body" do
              it "returns nil" do
                assert_nil transaction.response.body
              end
            end

            describe "#headers" do
              it "returns the headers" do
                assert_equal "HTTP/1.1 200 OK", transaction.response.headers
              end
            end
          end

          describe "when the raw_http_capture#raw_received returns an empty string" do
            before { capture.send(:raw_received).stubs(:string).returns('') }

            describe "#body" do
              it "returns nil" do
                assert_nil transaction.response.body
              end
            end

            describe "#headers" do
              it "returns nil" do
                assert_nil transaction.response.headers
              end
            end
          end

          describe "when there is invalid UTF-8 in the body" do
            before { capture.send(:raw_received).stubs(:string).returns("HTTP/1.1 200 OK\r\n\r\nOl\xAD") }

            describe "#body" do
              it "returns nil" do
                assert_equal "Ol\xAD", transaction.response.body
              end
            end

            describe "#headers" do
              it "returns nil" do
                assert_equal "HTTP/1.1 200 OK", transaction.response.headers
              end
            end
          end
        end

        describe "#request" do
          it "returns a request object" do
            assert_instance_of RawHTTPCapture::Transaction::Request, transaction.request
          end
        end

        describe "Request" do
          describe "when the raw_http_capture#raw_sent#string returns a proper http response with a body" do
            before { capture.send(:raw_sent).stubs(:string => "GET / HTTP/1.1\r\n\r\n{}") }

            describe "#body" do
              it "returns the body" do
                assert_equal "{}", transaction.request.body
              end
            end

            describe "#headers" do
              it "returns the headers" do
                assert_equal "GET / HTTP/1.1", transaction.request.headers
              end
            end

            describe "#raw" do
              it "returns the entire response" do
                assert_equal "GET / HTTP/1.1\r\n\r\n{}", transaction.request.raw
              end
            end
          end

          describe "when the raw_http_capture#raw_sent#string returns a proper http response without a body" do
            before { capture.send(:raw_sent).stubs(:string).returns("GET / HTTP/1.1\r\n\r\n") }

            describe "#body" do
              it "returns nil" do
                assert_nil transaction.request.body
              end
            end

            describe "#headers" do
              it "returns the headers" do
                assert_equal "GET / HTTP/1.1", transaction.request.headers
              end
            end
          end

          describe "when the raw_http_capture#raw_sent returns an empty string" do
            before { capture.send(:raw_sent).stubs(:string).returns('') }

            describe "#body" do
              it "returns nil" do
                assert_nil transaction.request.body
              end
            end

            describe "#headers" do
              it "returns nil" do
                assert_nil transaction.request.headers
              end
            end
          end
        end
      end
    end
  end
end
