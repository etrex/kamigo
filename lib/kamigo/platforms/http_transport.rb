# frozen_string_literal: true
require 'net/http'
require 'openssl'
require 'json'
require 'timeout'

module Kamigo
  module Platforms
    # An explicit API rejection; this is not proof that every platform operation is retryable.
    class DeliveryRejected < StandardError
      REASONS = %w[chat_not_found migrated_chat bot_blocked not_member message_too_long invalid_entities slow_mode other].freeze
      attr_reader :status, :reason, :migrate_to_chat_id
      def initialize(status: nil, reason: nil, migrate_to_chat_id: nil)
        @status = status
        @reason = REASONS.include?(reason) ? reason : nil
        @migrate_to_chat_id = migrate_to_chat_id if migrate_to_chat_id.is_a?(Integer) && migrate_to_chat_id.negative? && migrate_to_chat_id.abs < (1 << 52)
        super('platform rejected delivery')
      end
    end
    class DeliveryRateLimited < DeliveryRejected
      attr_reader :retry_after
      def initialize(retry_after:, status: 429, reason: nil, migrate_to_chat_id: nil)
        raise ArgumentError, "invalid retry delay" unless retry_after.is_a?(Numeric) && retry_after.positive? && retry_after.finite?
        @retry_after = retry_after
        super(status: 429, reason: reason, migrate_to_chat_id: migrate_to_chat_id)
      end
    end
    # The provider may already have accepted the message. Never blindly retry.
    class DeliveryUncertain < StandardError; end

    class HttpTransport
      def initialize(token:, open_timeout: 3, read_timeout: 5, write_timeout: 5,
                     deadline: 10, max_request_bytes: 1_048_576, max_response_bytes: 1_048_576,
                     http_factory: nil, local_http_endpoint: nil)
        [open_timeout, read_timeout, write_timeout, deadline, max_request_bytes, max_response_bytes].each do |value|
          raise ArgumentError, 'limits must be positive' unless value.is_a?(Numeric) && value.positive? && value.finite?
        end
        @local_endpoint = local_http_endpoint && URI(local_http_endpoint)
        if @local_endpoint && !(@local_endpoint.scheme == 'http' && @local_endpoint.host == '127.0.0.1' && @local_endpoint.path.empty? && !@local_endpoint.userinfo && !@local_endpoint.query && !@local_endpoint.fragment)
          raise ArgumentError, 'local endpoint must be a loopback HTTP origin'
        end
        @token = token
        @open_timeout, @read_timeout, @write_timeout, @deadline = open_timeout, read_timeout, write_timeout, deadline
        @max_request_bytes, @max_response_bytes = max_request_bytes, max_response_bytes
        # Disable environment proxies: credentials must only be sent to the fixed platform host.
        @http_factory = http_factory || ->(host, port) { Net::HTTP.new(host, port, nil) }
      end

      def inspect
        '#<Kamigo::Platforms::HttpTransport credentials=[FILTERED]>'
      end

      def call(platform:, operation:, payload:)
        platform, operation = platform.to_sym, operation.to_sym
        unless (platform == :line && %i[push reply leave_group leave_room].include?(operation)) || (platform == :telegram && %i[send_message leave_chat].include?(operation))
          raise ArgumentError, 'unsupported platform operation'
        end
        body = JSON.generate(payload)
        raise ArgumentError, 'request body exceeds limit' if body.bytesize > @max_request_bytes
        token = credential
        raise ArgumentError, 'invalid platform credential' unless token.is_a?(String) && !token.empty? && token.match?(/\A[A-Za-z0-9_:+\/=.-]+\z/)
        raise ArgumentError, 'invalid Telegram credential' if platform == :telegram && !token.match?(/\A[0-9]+:[A-Za-z0-9_-]+\z/)
        host = platform == :line ? 'api.line.me' : 'api.telegram.org'
        path = if platform == :line && %i[leave_group leave_room].include?(operation)
          subject = payload.fetch(:conversation_id).to_s
          raise ArgumentError, 'invalid conversation ID' unless subject.match?(/\A[A-Za-z0-9_-]{1,200}\z/)
          body = '{}'
          "/v2/bot/#{operation == :leave_group ? 'group' : 'room'}/#{subject}/leave"
        elsif platform == :line
          "/v2/bot/message/#{operation}"
        else
          "/bot#{token}/#{operation == :leave_chat ? 'leaveChat' : 'sendMessage'}"
        end
        request = Net::HTTP::Post.new(path)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        request['Accept-Encoding'] = 'identity'
        request['Authorization'] = "Bearer #{token}" if platform == :line
        request.body = body
        perform(host, request, platform, operation)
      end

      private

      def credential
        @token.respond_to?(:call) ? @token.call : @token
      rescue StandardError
        raise ArgumentError, 'platform credential unavailable', cause: nil
      end

      # Never retain provider descriptions: they may contain user content or
      # credential-bearing URLs. A bounded parser emits only known categories.
      def telegram_rejection(response, status)
        raw = +''
        response.read_body do |chunk|
          if raw.bytesize + chunk.bytesize > @max_response_bytes
            raise DeliveryUncertain, 'platform response exceeded limit' if status == 429
            return DeliveryRejected.new(status: status, reason: 'other')
          end
          raw << chunk
        end
        result = JSON.parse(raw)
        unless result.is_a?(Hash)
          raise DeliveryUncertain, 'invalid platform response' if status == 429
          return DeliveryRejected.new(status: status, reason: 'other')
        end
        parameters = result['parameters'].is_a?(Hash) ? result['parameters'] : {}
        migrated = parameters['migrate_to_chat_id']
        migrated = nil unless migrated.is_a?(Integer) && migrated.negative? && migrated.abs < (1 << 52)
        description = result['description'].is_a?(String) ? result['description'].downcase : ''
        reason = if migrated then 'migrated_chat'
        elsif description.include?('chat not found') then 'chat_not_found'
        elsif description.include?('bot was blocked') then 'bot_blocked'
        elsif description.include?('bot was kicked') || description.include?('bot is not a member') then 'not_member'
        elsif description.include?('message is too long') || description.include?('message_too_long') then 'message_too_long'
        elsif description.include?("can't parse entities") || description.include?('entity bounds') then 'invalid_entities'
        elsif description.include?('slow mode') || description.include?('slowmode') || description.include?('slow_mode') then 'slow_mode'
        else 'other'
        end
        retry_after = parameters['retry_after']
        if status == 429 && result['ok'] == false && retry_after.is_a?(Integer) && retry_after.positive?
          DeliveryRateLimited.new(retry_after: retry_after, reason: reason, migrate_to_chat_id: migrated)
        else
          DeliveryRejected.new(status: status, reason: reason, migrate_to_chat_id: migrated)
        end
      rescue StandardError
        raise DeliveryUncertain, 'delivery was not confirmed', cause: nil if status == 429
        # The HTTP status still proves rejection if its optional diagnostic body
        # is malformed, interrupted or exceeds the deadline. Do not retry it.
        DeliveryRejected.new(status: status, reason: 'other')
      end

      def perform(host, request, platform, operation)
        http = @http_factory.call(@local_endpoint ? @local_endpoint.host : host, @local_endpoint ? @local_endpoint.port : 443)
        http.use_ssl = @local_endpoint.nil?
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.open_timeout, http.read_timeout, http.write_timeout = @open_timeout, @read_timeout, @write_timeout
        http.max_retries = 0
        Timeout.timeout(@deadline) do
          http.start do |session|
            session.request(request) do |response|
              status = response.code.to_i
              if (400..499).cover?(status)
                if platform == :telegram
                  raise telegram_rejection(response, status), cause: nil
                end
                raise DeliveryRejected.new(status: status), cause: nil
              end
              raise DeliveryUncertain, 'platform response did not confirm acceptance', cause: nil unless (200..299).cover?(status) || (platform == :telegram && status == 429)
              raw = +''
              response.read_body do |chunk|
                raise DeliveryUncertain, 'platform response exceeded limit', cause: nil if raw.bytesize + chunk.bytesize > @max_response_bytes
                raw << chunk
              end
              result = JSON.parse(raw)
              raise DeliveryUncertain, 'invalid platform response', cause: nil unless result.is_a?(Hash)
              if platform == :telegram
                retry_after = result.dig('parameters', 'retry_after') if result['parameters'].is_a?(Hash)
                if status == 429 && result['ok'] == false && retry_after.is_a?(Integer) && retry_after.positive?
                  raise DeliveryRateLimited.new(retry_after: retry_after), cause: nil
                end
                raise DeliveryRejected.new(status: status), cause: nil if status == 429
                raise DeliveryRejected.new(status: status), cause: nil if result['ok'] == false
                raise DeliveryUncertain, 'invalid platform response', cause: nil unless result['ok'] == true && (operation == :leave_chat ? result['result'] == true : result['result'].is_a?(Hash) && result['result']['message_id'].is_a?(Integer))
              end
              return { status: status, request_id: response['x-line-request-id'], message_id: platform == :telegram && operation == :send_message ? result['result']['message_id'] : nil }.freeze
            end
          end
        end
      rescue DeliveryRejected, DeliveryUncertain
        raise
      rescue StandardError
        # Net::HTTP/SSL errors may contain a credential-bearing Telegram path.
        raise DeliveryUncertain, 'delivery was not confirmed', cause: nil
      end
    end
  end
end
