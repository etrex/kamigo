require_relative 'base'
module Kamigo
  module Platforms
    class Line < Base
      def verify!(body:, headers:)
        expected = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', @secret, body))
        raise VerificationError, 'invalid LINE signature' unless equal_secret?(expected, header(headers, 'x-line-signature'))
        true
      end

      def events(body:, headers:, connection:)
        verify!(body: body, headers: headers)
        data = parse(body)
        raise InvalidEvent, 'events must be an array' unless data.is_a?(Hash) && data['events'].is_a?(Array)
        data['events'].map do |item|
          source = item.fetch('source', {})
          id = item['webhookEventId']
          raise InvalidEvent, 'missing webhook event ID' if id.to_s.empty?
          Event.new(platform: :line, connection: connection, id: id,
                    actor_id: source['userId'], conversation_id: source['groupId'] || source['roomId'] || source['userId'],
                    type: item.fetch('type').to_sym, text: item.dig('message', 'type') == 'text' ? item.dig('message', 'text') : nil,
                    payload: item)
        end
      rescue KeyError, TypeError, NoMethodError => error
        raise InvalidEvent, error.message
      end

      def deliver(conversation_id: nil, messages:, reply_token: nil, action: nil)
        if action
          raise ArgumentError, 'unsupported LINE action' unless %w[leave_group leave_room].include?(action.to_s) && messages == [] && reply_token.nil?
          return transmit(platform: :line, operation: action.to_sym, payload: { conversation_id: conversation_id })
        end
        raise ArgumentError, 'LINE expects 1..5 messages' unless messages.is_a?(Array) && (1..5).cover?(messages.size)
        messages.each do |message|
          raise ArgumentError, 'LINE message must have a type' unless message.is_a?(Hash) && (message[:type] || message['type'])
        end
        result = if reply_token
          raise ArgumentError, 'reply token must not be empty' if reply_token.to_s.empty?
          transmit(platform: :line, operation: :reply, payload: { replyToken: reply_token, messages: messages })
        else
          raise ArgumentError, 'conversation ID is required' if conversation_id.to_s.empty?
          transmit(platform: :line, operation: :push, payload: { to: conversation_id, messages: messages })
        end
        yield(message_indexes: (0...messages.length).to_a, provider_receipt: result) if block_given?
        result
      end
    end
  end
end
