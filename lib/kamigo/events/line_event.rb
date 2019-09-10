module Kamigo
  module Events
    class LineEvent < BasicEvent
      attr_accessor :reply_token
    end
  end
end