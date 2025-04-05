module Kamigo
  module Clients
    module LineClient
      def client
        @client ||= Line::Bot::Client.new do |config|
          config.channel_id = Kamigo.line_messaging_api_channel_id
          config.channel_secret = Kamigo.line_messaging_api_channel_secret
          config.channel_token = Kamigo.line_messaging_api_channel_token
        end
      end

      def validate_signature(request, body)
        signature = request.env['HTTP_X_LINE_SIGNATURE']
        client.validate_signature(body, signature)
      end

      private

      def reset_client
        @client = nil
      end
    end
  end
end
