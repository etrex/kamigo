require 'uri'

class LineController < ApplicationController
  protect_from_forgery with: :null_session

  def entry
    parser = Kamigo::EventParsers::LineEventParser.new
    events = parser.parse_events(request)
    events.each do |event|
      output = process_event(event) || Kamigo.line_default_message
      responser = Kamigo::EventResponsers::LineEventResponser.new
      response = responser.response_event(event, output)
    end
    head :ok
  end

  private

  def process_event(event)
    Kamigo.line_event_processors.each do |processor|
      processor.request = request
      processor.form_authenticity_token = form_authenticity_token
      output = processor.process(event)
      return output if output.present?
    end
    nil
  end
end
