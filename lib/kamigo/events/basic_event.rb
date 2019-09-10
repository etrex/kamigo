module Kamigo
  module Events
    class BasicEvent
      attr_accessor :platform_type
      attr_accessor :message
      attr_accessor :message_type
      attr_accessor :source_type
      attr_accessor :source_group_id
      attr_accessor :source_user_id
      attr_accessor :payload
    end
  end
end