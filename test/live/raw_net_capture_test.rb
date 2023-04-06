# encoding: utf-8
require File.expand_path '../../helper', __FILE__

class RawNetCaptureTest < MiniTest::Test
  describe RawNetCapture do
    let(:capture) { RawNetCapture.new }

    describe "with get to example.org" do
      before do
        uri = URI.parse("https://www.example.org/")
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true
        @http.set_debug_output capture
        @http.get(uri.request_uri)
      end

      it "captures raw HTTP request and response" do
        raw_sent = capture.raw_traffic.select { |x| x[0] == :sent }.map { |x| x[1] }.join
        raw_received = capture.raw_traffic.select { |x| x[0] == :received }.map { |x| x[1] }.join

        assert_match(/\AGET \/ HTTP\/1\.1.*Host: www\.example\.org.*\z/m, raw_sent)
        assert_match(/\AHTTP\/1\.1 200 OK.*\z/m, raw_received)
      end

      describe "and another get with query string" do
        before do
          uri = URI.parse("https://www.example.org/?test")
          @http.get(uri.request_uri)
        end

        it "captures the last request when multiple are invoked" do
          raw_sent = capture.raw_traffic.select { |x| x[0] == :sent }.map { |x| x[1] }.join
          raw_received = capture.raw_traffic.select { |x| x[0] == :received }.map { |x| x[1] }.join

          assert_match(/[^\A]GET \/\?test HTTP\/1\.1.*Host: www\.example\.org.*\z/m, raw_sent)
          assert_match(/[^\A]HTTP\/1.1 200 OK.*\z/m, raw_received)
        end
      end
    end
  end
end
