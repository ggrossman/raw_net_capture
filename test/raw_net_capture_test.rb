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
      response = http.request(Net::HTTP::Get.new(uri.request_uri))

      assert_match(/\AGET \/ HTTP\/1.1.*Host: www.google.com.*\z/m, capture.raw_sent.string)
      assert_match(/\AHTTP\/1.1 200 OK.*\z/m, capture.raw_received.string)
    end
  end
end
