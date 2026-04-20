module Kamigo
  module EventResponsers
    class LineEventResponser
      include Kamigo::Clients::LineClient

      def initialize(account: nil)
        @client = account&.client
      end

      def response_event(event, message)
        return nil if message.blank?
        message = JSON.parse(message) if message.is_a?(String) && (message.start_with?("{") || message.start_with?("["))
        return nil if message.blank?
        response = client.reply_message(event.reply_token, message)
        response
      end
    end
  end
end
