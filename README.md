[![Build Status](https://travis-ci.org/zendesk/raw_net_capture.png)](https://travis-ci.org/zendesk/raw_net_capture)

raw_net_capture
===============

Sometimes, it's useful to capture the input/output of a network operation
when working with Ruby's `net` module. For instance, you might want to
capture the entire raw HTTP request and response in a Web service call to
log for troubleshooting purposes.

Ruby has a built-in mechanism for this called `debug_output`. For example,
the following Ruby script will display the data sent and received to
access the Google home page::

```
require 'uri'
require 'net/http'
uri = URI.parse("https://www.google.com/")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.set_debug_output $stderr
response = http.request(Net::HTTP::Get.new(uri.request_uri))
```

The output from this program looks like this:

```
opening connection to www.google.com:443...
opened
starting SSL for www.google.com:443...
SSL established
<- "GET / HTTP/1.1\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nConnection: close\r\nHost: www.google.com\r\n\r\n"
-> "HTTP/1.1 200 OK\r\n"
-> "Date: Wed, 17 Dec 2014 23:57:50 GMT\r\n"
-> "Expires: -1\r\n"
-> "Cache-Control: private, max-age=0\r\n"
-> "Content-Type: text/html; charset=ISO-8859-1\r\n"
-> "Set-Cookie: PREF=ID=5e20db0a42f4b985:FF=0:TM=1418860670:LM=1418860670:S=JH6c4oJay1WzDmX5; expires=Fri, 16-Dec-2016 23:57:50 GMT; path=/; domain=.google.com\r\n"
-> "Set-Cookie: NID=67=d2pbOvUcXwKtg54nUN6V1pVxF9D2nDTgRZ9_g1-ybyOXy4za24EkzQBF3DKQp3kxII8IW1RiQZqTKMAO1MLxaIpvG9F-c1OinygaN-hlDiTMVWCWOFALfWCnOlQCAIC4; expires=Thu, 18-Jun-2015 23:57:50 GMT; path=/; domain=.google.com; HttpOnly\r\n"
-> "P3P: CP=\"This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info.\"\r\n"
-> "Server: gws\r\n"
-> "X-XSS-Protection: 1; mode=block\r\n"
-> "X-Frame-Options: SAMEORIGIN\r\n"
-> "Alternate-Protocol: 443:quic,p=0.02\r\n"
-> "Connection: close\r\n"
-> "\r\n"
```

Note that all of the traffic is prefixed with `<-` or `->` to indicate whether
it's sent or received, and all of the actual data that went over the wire
is enclosed in `"` and control characters such as `\r` and `\n` are escaped.
This is fine for human-readability, but you may want to capture the raw
data instead.

To that end, this gem provides a simple extension to Ruby's `debug_output`
mechanism. `RawNetCapture` is a subclass of `StringIO` that can be supplied
to the `set_debug_output` method.

If the object supplied to `set_debug_output` is an instance of
`RawNetCapture`, it will still capture all of the text in the above
format just like any other `StringIO`, but there will also be two
additional `StringIO` objects available on the `RawNetCapture` object,
`raw_sent` and `raw_received`. These will contain the raw data sent
and received during the network operation.

Since separating the sent and received data into `raw_sent` and
`raw_received` makes it impossible to track what data was sent and
received in what order like the standard debug output format,
this is mostly useful for HTTP traffic where there is a clear request
and response to be captured.

### Example

```
require 'net/https'
require 'uri'
require 'raw_net_capture'

capture = RawNetCapture.new

uri = URI.parse("https://www.google.com/")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.set_debug_output capture
response = http.request(Net::HTTP::Get.new(uri.request_uri))

puts "*** RAW REQUEST"
puts capture.raw_sent.string

puts "*** RAW RESPONSE"
puts capture.raw_received.string
```

### Authors

[Gary Grossman](https://github.com/ggrossman)

[Victor Kmita](https://github.com/vkmita)

### License

Apache License 2.0
