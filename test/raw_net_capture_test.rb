# encoding: utf-8
require File.expand_path '../helper', __FILE__

require 'net/https'
require 'uri'

class RawNetCaptureTest < MiniTest::Test
  describe RawNetCapture do
    it "captures raw HTTP request and response" do
      capture = RawNetCapture.new

      uri = URI.parse("https://www.google.com/")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.set_debug_output capture
      response = http.get(uri.request_uri)

      raw_sent = capture.raw_traffic.select { |x| x[0] == :sent }.map { |x| x[1] }.join
      raw_received = capture.raw_traffic.select { |x| x[0] == :received }.map { |x| x[1] }.join

      assert_match(/\AGET \/ HTTP\/1.1.*Host: www.google.com.*\z/m, raw_sent)
      assert_match(/\AHTTP\/1.1 200 OK.*\z/m, raw_received)
    end
  end

  describe RawHTTPCapture do
    it "captures raw HTTP request and response" do
      capture = RawHTTPCapture.new

      uri = URI.parse("https://www.google.com/")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.set_debug_output capture
      response = http.get(uri.request_uri)

      assert_match(/\AGET \/ HTTP\/1.1.*Host: www.google.com.*\z/m, capture.raw_sent.string)
      assert_match(/\AHTTP\/1.1 200 OK.*\z/m, capture.raw_received.string)
    end

    describe "#headers_only!" do
      it "removes HTTP response body" do
        capture = RawHTTPCapture.new

        uri = URI.parse("https://www.google.com/")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.set_debug_output capture
        response = http.get(uri.request_uri)

        original_length = capture.raw_received.string.length
        assert true, capture.headers_only!

        headers = capture.raw_received.string
        assert headers.length < original_length
        assert headers.start_with?('HTTP/1.1 200 OK')
        assert headers.end_with?("Connection: close\r\n")
      end
    end
  end
end
