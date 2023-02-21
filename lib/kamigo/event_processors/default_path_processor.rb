module Kamigo
  module EventProcessors
    class DefaultPathProcessor
      attr_accessor :request
      attr_accessor :form_authenticity_token

      def process(event)
        return nil if Kamigo.default_path.nil?
        reserve_route(URI::Parser.new.escape(Kamigo.default_path), http_method: Kamigo.default_http_method, request_params: event.platform_params, format: :line)
      end

      private

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