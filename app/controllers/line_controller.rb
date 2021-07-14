require 'uri'

class LineController < ActionController::Base
  protect_from_forgery with: :null_session

  def entry
    request_handler = Kamigo::RequestHandlers::LineRequestHandler.new(request, form_authenticity_token)
    request_handler.handle
    head :ok
  end
end
