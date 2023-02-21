module Kamigo
  module RequestHandlers
    class LineRequestHandler
      def initialize(request, form_authenticity_token)
        @request = request
        @form_authenticity_token = form_authenticity_token
      end

      def handle
        parser = EventParsers::LineEventParser.new
        events = parser.parse_events(@request)
        events.each do |event|
          output = process_event(event)
          responser = EventResponsers::LineEventResponser.new
          response = responser.response_event(event, output)
        end
      end

      private

      def process_event(event)
        Kamigo.line_event_processors.each do |processor|
          processor.request = @request
          processor.form_authenticity_token = @form_authenticity_token
          output = processor.process(event)
          return output if output.present?
        end
        nil
      end
    end
  end
end