require File.expand_path '../../helper', __FILE__

class RawHTTPCaptureTest < MiniTest::Test
  describe RawHTTPCapture do
    let(:capture) { RawHTTPCapture.new }

    describe "#transactions" do
      it "returns an array of transactions" do
        assert_instance_of Array, capture.transactions
      end
    end

    describe "Transaction" do
      let(:transaction) { RawHTTPCapture::Transaction.new }

      describe "#response" do
        it "returns a response object" do
          assert_instance_of RawHTTPCapture::Transaction::Response, transaction.response
        end
      end

      describe "Response" do
        describe "when the raw_http_capture#raw_received#string returns a proper http response with a body" do
          before { transaction.response.raw_io.stubs(:string).returns("HTTP/1.1 200 OK\r\n\r\n{}") }

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
          before { transaction.response.raw_io.stubs(:string).returns("HTTP/1.1 200 OK\r\n\r\n") }

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
          before { transaction.response.raw_io.stubs(:string).returns('') }

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
          before { transaction.response.raw_io.stubs(:string).returns("HTTP/1.1 200 OK\r\n\r\nOl\xAD") }

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
          before { transaction.request.raw_io.stubs(:string).returns("GET / HTTP/1.1\r\n\r\n{}") }

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
          before { transaction.request.raw_io.stubs(:string).returns("GET / HTTP/1.1\r\n\r\n") }

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
          before { transaction.request.raw_io.stubs(:string).returns('') }

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
