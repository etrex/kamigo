module Kamigo
  module EventProcessors
    class RailsRouterProcessor
      attr_accessor :request
      attr_accessor :form_authenticity_token

      def initialize
      end

      def process(event)
        http_method, path, request_params = kamiform_context(event)
        http_method, path, request_params = language_understanding(event.message) if http_method.nil?
        encoded_path = URI.encode(path)
        request_params = event.platform_params.merge(request_params)
        output = reserve_route(encoded_path, http_method: http_method, request_params: request_params, format: :line)
        return output if output.present?

        return nil if Kamigo.default_path.nil?
        reserve_route(URI.encode(Kamigo.default_path), http_method: Kamigo.default_http_method, request_params: request_params, format: :line)
      end

      private

      def kamiform_context(event)
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
        request_params[:authenticity_token] = @form_authenticity_token
        http_method = request_params["_method"]&.upcase || http_method || "GET"
        [http_method, path, request_params]
      end

      def parse_json(string)
        return {} if string.strip.empty?
        JSON.parse(string)
      end

      def reserve_route(path, http_method: "GET", request_params: nil, format: nil)
        path = "/#{path}" unless path.start_with? "/"

        @request.request_method = http_method
        @request.path_info = path
        @request.format = format if format.present?
        @request.request_parameters = request_params if request_params.present?

        # req = Rack::Request.new
        # env = {Rack::RACK_INPUT => StringIO.new}

        res = Rails.application.routes.router.serve(@request)
        res[2].body if res[2].respond_to?(:body)
      end
    end
  end
end