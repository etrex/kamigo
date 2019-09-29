module Kamigo
  module Events
    class LineEvent < BasicEvent
      attr_accessor :reply_token

      def initialize
        self.platform_type = 'line'
      end
    end
  end
end