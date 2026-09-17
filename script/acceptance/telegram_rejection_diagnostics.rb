# Public API manual acceptance: only the external Telegram HTTP endpoint is a fixture.
require 'socket'
require 'json'
require_relative '../../lib/kamigo/platforms/http_transport'
cases = [
  [400, {ok: false, description: 'Bad Request: chat not found SECRET_TEXT'}, 'chat_not_found'],
  [400, {ok: false, description: 'upgraded SECRET_TEXT', parameters: {migrate_to_chat_id: -100123}}, 'migrated_chat'],
  [403, {ok: false, description: 'Forbidden: bot was blocked by the user SECRET_TEXT'}, 'bot_blocked'],
  [403, {ok: false, description: 'Forbidden: bot is not a member of the channel chat SECRET_TEXT'}, 'not_member'],
  [400, {ok: false, description: 'Bad Request: message is too long SECRET_TEXT'}, 'message_too_long'],
  [400, {ok: false, description: "Bad Request: can't parse entities SECRET_TEXT"}, 'invalid_entities'],
  [429, {ok: false, description: 'slow mode SECRET_TEXT', parameters: {retry_after: 12}}, 'slow_mode'],
  [429, {ok: false, description: 'Too Many Requests SECRET_TEXT', parameters: {retry_after: 792}}, 'other'],
  [400, 'malformed SECRET_TEXT', 'other'],
  [400, 'x' * 5000, 'other'],
  [400, {ok: false, parameters: {migrate_to_chat_id: 'SECRET_TEXT'}}, 'other']
]
server = TCPServer.new('127.0.0.1', 0)
thread = Thread.new do
  cases.each do |status, body, _reason|
    client = server.accept
    client.gets
    length = 0
    while (line = client.gets) != "\r\n"
      length = line.split(':', 2).last.to_i if line.downcase.start_with?('content-length:')
    end
    client.read(length)
    raw = body.is_a?(Hash) ? JSON.generate(body) : body
    client.write("HTTP/1.1 #{status} Rejected\r\nContent-Length: #{raw.bytesize}\r\nConnection: close\r\n\r\n#{raw}")
    client.close
  end
end
transport = Kamigo::Platforms::HttpTransport.new(token: '123:SECRET_TOKEN', local_http_endpoint: "http://127.0.0.1:#{server.addr[1]}", max_response_bytes: 1024)
cases.each_with_index do |(status, _body, expected), index|
  begin
    transport.call(platform: :telegram, operation: :send_message, payload: {chat_id: '-1', text: 'private input'})
    raise 'expected rejection'
  rescue Kamigo::Platforms::DeliveryRejected => error
    raise 'wrong classification' unless error.status == status && error.reason == expected
    raise 'leaked diagnostic' if error.full_message.include?('SECRET') || error.cause
    puts JSON.generate(case: index, status: error.status, reason: error.reason,
      retry_after: error.respond_to?(:retry_after) ? error.retry_after : nil, migrate_to_chat_id: error.migrate_to_chat_id)
  end
end
thread.join
server.close
