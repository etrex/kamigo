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
require "kamigo/event_processors/default_path_processor"
require "kamigo/event_processors/default_message_processor"
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
  @@line_event_processors = [
    EventProcessors::RailsRouterProcessor.new,
    EventProcessors::DefaultPathProcessor.new,
    EventProcessors::DefaultMessageProcessor.new
  ]

  # LINE Messaging API configuration
  mattr_accessor :line_messaging_api_channel_id
  @@line_messaging_api_channel_id = ENV["LINE_CHANNEL_ID"]

  mattr_accessor :line_messaging_api_channel_secret
  @@line_messaging_api_channel_secret = ENV["LINE_CHANNEL_SECRET"]

  mattr_accessor :line_messaging_api_channel_token
  @@line_messaging_api_channel_token = ENV["LINE_CHANNEL_TOKEN"]

  class << self
    delegate :line_login_channel_id, :line_login_channel_id=, to: :Kamiliff
    delegate :line_login_channel_secret, :line_login_channel_secret=, to: :Kamiliff
    delegate :line_login_redirect_uri, :line_login_redirect_uri=, to: :Kamiliff
    delegate :liff_url_compact, :liff_url_compact=, to: :Kamiliff
    delegate :liff_url_tall, :liff_url_tall=, to: :Kamiliff
    delegate :liff_url_full, :liff_url_full=, to: :Kamiliff
  end

  def self.setup
    yield self
  end
end
