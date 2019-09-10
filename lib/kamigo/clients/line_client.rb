module Kamigo
  module Clients
    module LineClient
      def client
        @client ||= Line::Bot::Client.new do |config|
          config.channel_secret = ENV['LINE_CHANNEL_SECRET']
          config.channel_token = ENV['LINE_CHANNEL_TOKEN']
        end
      end

      def validate_signature(request, body)
        signature = request.env['HTTP_X_LINE_SIGNATURE']
        client.validate_signature(body, signature)
      end
    end
  end
end
