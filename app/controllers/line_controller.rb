require 'uri'

class LineController < ActionController::Base
  protect_from_forgery with: :null_session

  def entry
    account = Kamigo.find_account(params[:account_name])
    request_handler = Kamigo::RequestHandlers::LineRequestHandler.new(request, form_authenticity_token, account: account)
    request_handler.handle
    head :ok
  end
end
