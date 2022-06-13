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
  # config.line_event_processors = [Kamigo::EventProcessors::RailsRouterProcessor.new]
end