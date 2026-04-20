module Kamigo
  module Events
    class BasicEvent
      attr_accessor :platform_type
      attr_accessor :message
      attr_accessor :message_type
      attr_accessor :source_type
      attr_accessor :source_group_id
      attr_accessor :source_user_id
      attr_accessor :profile
      attr_accessor :payload
      attr_accessor :account_name

      def platform_params
        {
          platform_type: platform_type,
          message: message,
          message_type: message_type,
          source_type: source_type,
          source_group_id: source_group_id,
          source_user_id: source_user_id,
          profile: profile,
          payload: payload,
          account_name: account_name
        }
      end
    end
  end
end