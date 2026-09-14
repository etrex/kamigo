require 'minitest/autorun'
require 'socket'
require_relative '../../lib/kamigo/event'
require_relative '../../lib/kamigo/connections'
require_relative '../../lib/kamigo/platforms/line'
require_relative '../../lib/kamigo/platforms/http_transport'

class MultiConnectionAcceptanceTest < Minitest::Test
  # CONNECTION-HTTP-001: docs/acceptance/connections.md
  def test_two_line_connections_verify_and_deliver_through_their_own_credentials
    listener = TCPServer.new('127.0.0.1', 0)
    received = Queue.new
    server = Thread.new do
      2.times do
        socket = listener.accept
        request_line = socket.gets
        headers = {}
        while (line = socket.gets) && line != "\r\n"
          key, value = line.split(':', 2)
          headers[key.downcase] = value.strip
        end
        body = socket.read(Integer(headers.fetch('content-length')))
        received << [request_line, headers.fetch('authorization'), JSON.parse(body)]
        response = '{}'
        socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{response.bytesize}\r\nConnection: close\r\n\r\n#{response}")
        socket.close
      end
    end
    origin = "http://127.0.0.1:#{listener.addr[1]}"
    secrets = {'alpha' => ['alpha-secret', 'alpha-token'], 'beta' => ['beta-secret', 'beta-token']}
    registry = Kamigo::Connections::Registry.new do |platform:, connection:|
      secret, token = secrets[connection]
      next unless platform == 'line' && secret
      transport = Kamigo::Platforms::HttpTransport.new(token: token, local_http_endpoint: origin)
      {platform: platform, connection: connection, identity_scope: 'shared-provider', conversation_scope: 'shared-conversations',
       adapter: Kamigo::Platforms::Line.new(secret: secret, transport: transport)}
    end
    body = JSON.generate(events: [{webhookEventId: 'same-event', type: 'message',
      source: {userId: 'user-1'}, replyToken: 'reply-1', message: {type: 'text', text: '卡米狗'}}])

    definitions = %w[alpha beta].map do |name|
      definition = registry.resolve(platform: :line, connection: name)
      signature = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', "#{name}-secret", body))
      event = definition.adapter.events(body: body, headers: {'X-Line-Signature' => signature}, connection: name).first
      assert_equal name, event.connection
      assert_equal 'shared-conversations', definition.conversation_scope
      definition
    end
    wrong_signature = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', 'alpha-secret', body))
    assert_raises(Kamigo::Platforms::VerificationError) do
      definitions.last.adapter.events(body: body, headers: {'X-Line-Signature' => wrong_signature}, connection: 'beta')
    end

    definitions.each_with_index do |definition, index|
      definition.adapter.deliver(messages: [{type: 'text', text: definition.connection}], reply_token: "reply-#{index}")
    end
    deliveries = 2.times.map { received.pop }.sort_by { |row| row[2].fetch('replyToken') }
    assert_equal ['Bearer alpha-token', 'Bearer beta-token'], deliveries.map { |row| row[1] }
    assert_equal ['alpha', 'beta'], deliveries.map { |row| row[2].fetch('messages').first.fetch('text') }
  ensure
    listener&.close
    server&.kill
    server&.join
  end
end
