require 'minitest/autorun'
require 'socket'
require_relative '../../lib/kamigo/platforms/http_transport'

class HttpTransportLeaveLoopbackTest < Minitest::Test
  def test_line_group_leave_round_trip_uses_the_official_path_and_empty_object
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
      received << [request_line, headers, body]
      response = '{}'
      socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nX-Line-Request-Id: leave-1\r\nContent-Length: #{response.bytesize}\r\nConnection: close\r\n\r\n#{response}")
      socket.close
    end
    transport = Kamigo::Platforms::HttpTransport.new(token: 'line-token', local_http_endpoint: "http://127.0.0.1:#{listener.addr[1]}")
    result = transport.call(platform: :line, operation: :leave_group, payload: {conversation_id: 'group_123'})
    assert_equal({status: 200, request_id: 'leave-1', message_id: nil}, result)
    request_line, headers, body = received.pop
    assert_equal "POST /v2/bot/group/group_123/leave HTTP/1.1\r\n", request_line
    assert_equal 'Bearer line-token', headers['authorization']
    assert_equal '{}', body
  ensure
    listener&.close
    server&.kill
    server&.join
  end

  def test_telegram_leave_round_trip_requires_a_true_result
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
      response = JSON.generate(ok: true, result: true)
      socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{response.bytesize}\r\nConnection: close\r\n\r\n#{response}")
      socket.close
    end
    transport = Kamigo::Platforms::HttpTransport.new(token: '123456:local-token', local_http_endpoint: "http://127.0.0.1:#{listener.addr[1]}")
    result = transport.call(platform: :telegram, operation: :leave_chat, payload: {chat_id: '-100123'})
    assert_equal({status: 200, request_id: nil, message_id: nil}, result)
    request_line, payload = received.pop
    assert_equal "POST /bot123456:local-token/leaveChat HTTP/1.1\r\n", request_line
    assert_equal({'chat_id' => '-100123'}, payload)
  ensure
    listener&.close
    server&.kill
    server&.join
  end
end
