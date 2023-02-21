module Kamigo
  module EventProcessors
    class DefaultMessageProcessor
      attr_accessor :request
      attr_accessor :form_authenticity_token

      def process(event)
        if event.platform_type == "line"
          return nil if Kamigo.line_default_message.nil?
          return Kamigo.line_default_message
        end
      end
    end
  end
end
