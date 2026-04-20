module Kamigo
  module RequestHandlers
    class LineRequestHandler
      def initialize(request, form_authenticity_token, account: nil)
        @request = request
        @form_authenticity_token = form_authenticity_token
        @account = account || Kamigo.default_account
      end

      def handle
        parser = EventParsers::LineEventParser.new(account: @account)
        events = parser.parse_events(@request)
        events.each do |event|
          event.account_name = @account.name
          output = process_event(event)
          responser = EventResponsers::LineEventResponser.new(account: @account)
          response = responser.response_event(event, output)
        end
      end

      private

      def process_event(event)
        Kamigo.line_event_processors.each do |processor|
          processor.request = @request
          processor.form_authenticity_token = @form_authenticity_token
          processor.account = @account if processor.respond_to?(:account=)
          output = processor.process(event)
          return output if output.present?
        end
        nil
      end
    end
  end
end
