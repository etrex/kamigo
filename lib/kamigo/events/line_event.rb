module Kamigo
  module Events
    class LineEvent < BasicEvent
      attr_accessor :reply_token

      def initialize
        self.platform_type = 'line'
      end

      def platform_params
        super.merge(replyToken: reply_token)
      end
    end
  end
end