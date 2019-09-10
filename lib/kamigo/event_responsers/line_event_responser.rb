module Kamigo
  module EventResponsers
    class LineEventResponser
      include Kamigo::Clients::LineClient

      def response_event(event, message)
        message = JSON.parse(message) if message.is_a? String
        response = client.reply_message(event.reply_token, message)
        response
      end
    end
  end
end
