require_relative 'base'
module Kamigo
  module Platforms
    class Telegram < Base
      def verify!(body:, headers:)
        raise VerificationError, 'invalid Telegram webhook secret' unless equal_secret?(@secret, header(headers, 'x-telegram-bot-api-secret-token'))
        true
      end

      def events(body:, headers:, connection:)
        verify!(body: body, headers: headers)
        item = parse(body)
        raise InvalidEvent, 'missing update ID' unless item.is_a?(Hash) && item['update_id'].is_a?(Integer)
        type = %w[message edited_message channel_post edited_channel_post callback_query my_chat_member chat_member].find { |key| item.key?(key) }
        return [] unless type
        content = item.fetch(type)
        chat = content['chat'] || content.dig('message', 'chat') || {}
        return [] if chat['id'].nil? # Inline-only callbacks have no conversation to route.
        [Event.new(platform: :telegram, connection: connection, id: item['update_id'].to_s,
                   actor_id: content.dig('from', 'id')&.to_s, conversation_id: chat['id']&.to_s,
                   type: type.to_sym, text: content['text'], payload: item)]
      rescue TypeError, NoMethodError => error
        raise InvalidEvent, error.message
      end

      def deliver(conversation_id:, messages:, action: nil)
        if action
          raise ArgumentError, 'unsupported Telegram action' unless action.to_s == 'leave_chat' && messages == [] && conversation_id.to_s.match?(/\A-?[0-9]+\z/)
          return transmit(platform: :telegram, operation: :leave_chat, payload: { chat_id: conversation_id })
        end
        raise ArgumentError, 'messages must be an array' unless messages.is_a?(Array)
        raise ArgumentError, 'conversation ID is required' if conversation_id.to_s.empty?
        messages.each do |message|
          value = message.is_a?(Hash) && (message[:text] || message['text'])
          raise ArgumentError, 'Telegram text must contain 1..4096 characters' unless value.is_a?(String) && (1..4096).cover?(value.length)
        end
        messages.map do |message|
          transmit(platform: :telegram, operation: :send_message, payload: message.merge(chat_id: conversation_id))
        end
      end
    end
  end
end
