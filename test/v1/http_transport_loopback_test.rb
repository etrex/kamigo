require 'minitest/autorun'
require 'socket'
require_relative '../../lib/kamigo/platforms/http_transport'

class HttpTransportLoopbackTest < Minitest::Test
  # HTTP-LOCAL-001: docs/acceptance/http_transport.md
  def test_real_loopback_telegram_http_round_trip
    listener = TCPServer.new('127.0.0.1', 0)
    received = Queue.new
    server = Thread.new do
      socket = listener.accept
      request_line = socket.gets
      headers = {}
      while (line = socket.gets) && line != "\r\n"
        key, value = line.split(':', 2)
        headers[key.downcase] = value.strip
      end
      body = socket.read(Integer(headers.fetch('content-length')))
      received << [request_line, JSON.parse(body)]
      response = JSON.generate(ok: true, result: { message_id: 3 })
      socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{response.bytesize}\r\nConnection: close\r\n\r\n#{response}")
      socket.close
    end
    transport = Kamigo::Platforms::HttpTransport.new(token: '123456:local-token', local_http_endpoint: "http://127.0.0.1:#{listener.addr[1]}")
    result = transport.call(platform: :telegram, operation: :send_message, payload: { chat_id: 'framework-local-acceptance', text: 'HTTP acceptance' })
    assert_equal 200, result[:status]
    assert_equal 3, result[:message_id]
    line, payload = received.pop
    assert_equal "POST /bot123456:local-token/sendMessage HTTP/1.1\r\n", line
    assert_equal({ 'chat_id' => 'framework-local-acceptance', 'text' => 'HTTP acceptance' }, payload)
  ensure
    listener&.close
    server&.kill
    server&.join
  end

  def test_remote_http_cannot_be_used_as_loopback_override
    assert_raises(ArgumentError) do
      Kamigo::Platforms::HttpTransport.new(token: 'synthetic', local_http_endpoint: 'http://example.test')
    end
  end
end
