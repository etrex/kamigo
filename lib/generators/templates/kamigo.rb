Kamigo.setup do |config|
  # When user input doesn't match the route, Kamigo will pass the reuqest to default_path with default_http_method.
  # config.default_path = "/"
  # config.default_http_method = "GET"

  # When Kamigo don't know what message to reply, then Kamigo reply the line_default_message.
  # config.line_default_message = {
  #   type: "text",
  #   text: "Sorry, I don't understand your message."
  # }

  # When line_default_message is nil, then Kamigo don't reply message.
  # config.line_default_message = nil

  # When Kamigo receive a request, then Kamigo will process the request with the following processors.
  # config.line_event_processors = [
  #   EventProcessors::RailsRouterProcessor.new,
  #   EventProcessors::DefaultPathProcessor.new,
  #   EventProcessors::DefaultMessageProcessor.new
  # ]

  # LINE Messaging API configuration
  # By default, these values are read from environment variables:
  # LINE_CHANNEL_ID, LINE_CHANNEL_SECRET, and LINE_CHANNEL_TOKEN
  # You can override them here if needed:
  #
  # config.line_messaging_api_channel_id = "your_channel_id"
  # config.line_messaging_api_channel_secret = "your_channel_secret"
  # config.line_messaging_api_channel_token = "your_channel_token"
end