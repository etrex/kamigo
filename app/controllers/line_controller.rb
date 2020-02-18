require 'uri'

class LineController < ApplicationController
  include ReverseRoute
  protect_from_forgery with: :null_session

  def entry
    parser = Kamigo::EventParsers::LineEventParser.new
    events = parser.parse_events(request)
    events.each do |event|
      process_event(event)
    end
    head :ok
  end

  private

  def process_event(event)
    http_method, path, request_params = slot_filling(event)
    http_method, path, request_params = language_understanding(event.message) if http_method.nil?
    encoded_path = URI.encode(path)
    request_params = event.platform_params.merge(request_params)
    output = reserve_route(encoded_path, http_method: http_method, request_params: request_params, format: :line)
    responser = Kamigo::EventResponsers::LineEventResponser.new
    response =  responser.response_event(event, output)
    puts response.body
  rescue NoMethodError => e
    puts e.full_message
    responser = Kamigo::EventResponsers::LineEventResponser.new
    response =  responser.response_event(event, {
      type: "text",
      text: "404 not found"
    })
  end

  def slot_filling(event)
    begin
      Kamiform
    rescue StandardError
      return [nil, nil, nil]
    end
    form = Kamiform.find_by(
      platform_type: event.platform_type,
      source_group_id: event.source_group_id
    )
    return [nil, nil, nil] if form.nil?

    http_method = form.http_method
    path = form.path
    request_params = form.params

    # fill
    if form.field['.'].nil?
      request_params[form.field] = event.message
    else
      *head, tail = form.field.split('.')
      request_params.dig(*head)[tail] = event.message
    end
    form.destroy
    [http_method.upcase, path, request_params]
  end

  def language_understanding(text)
    http_method = %w[GET POST PUT PATCH DELETE].find do |http_method|
      text.start_with? http_method
    end
    text = text[http_method.size..-1] if http_method.present?
    text = text.strip
    lines = text.split("\n").compact
    path = lines.shift
    request_params = parse_json(lines.join(""))
    request_params[:authenticity_token] = form_authenticity_token
    http_method = request_params["_method"]&.upcase || http_method || "GET"
    [http_method, path, request_params]
  end

  def parse_json(string)
    return {} if string.strip.empty?
    JSON.parse(string)
  end

end
