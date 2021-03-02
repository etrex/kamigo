require "kamigo/engine"
require "line-bot-api"
require "kamiflex"
require "kamiliff"
require "kamigo/clients/line_client"
require "kamigo/events/basic_event"
require "kamigo/events/line_event"
require "kamigo/event_parsers/line_event_parser"
require "kamigo/event_responsers/line_event_responser"
require "kamigo/event_processors/rails_router_processor"
require "kamigo/request_handlers/line_request_handler"

module Kamigo
  mattr_accessor :line_default_message
  @@line_default_message = {
    type: "text",
    text: "Sorry, I don't understand your message."
  }

  mattr_accessor :default_path
  @@default_path = nil

  mattr_accessor :default_http_method
  @@default_http_method = "GET"

  mattr_accessor :line_event_processors
  @@line_event_processors = [EventProcessors::RailsRouterProcessor.new]

  def self.setup
    yield self
  end
end
