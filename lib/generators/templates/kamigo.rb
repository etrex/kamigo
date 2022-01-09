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

  # Integrate with line login
  # config.line_login_channel_id = ENV["LINE_LOGIN_CHANNEL_ID"]
  # config.line_login_channel_secret = ENV["LINE_LOGIN_CHANNEL_SECRET"]
  # config.line_login_redirect_uri = ENV["LINE_LOGIN_REDIRECT_URI"]

  # Integrate with liff
  # config.liff_url_compact = ENV["LIFF_COMPACT"]
  # config.liff_url_tall = ENV["LIFF_TALL"]
  # config.liff_url_full = ENV["LIFF_FULL"]

  # Integrate with line messaging api
  # config.line_message_api_channel_id = ENV["LINE_CHANNEL_ID"]
  # config.line_message_api_channel_secret = ENV["LINE_CHANNEL_SECRET"]
  # config.line_message_api_channel_token = ENV["LINE_CHANNEL_TOKEN"]
end