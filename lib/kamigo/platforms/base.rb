require 'json'
require 'openssl'
require 'base64'

module Kamigo
  module Platforms
    class VerificationError < StandardError; end
    class InvalidEvent < StandardError; end
    class Base
      def initialize(secret:, transport: nil)
        raise ArgumentError, 'secret must not be empty' if secret.to_s.empty?
        @secret, @transport = secret.to_s.dup.freeze, transport
      end

      private

      def header(headers, name)
        headers.each_pair.find { |key, _| key.to_s.downcase.tr('_', '-').delete_prefix('http-') == name.downcase }&.last.to_s
      end

      def equal_secret?(expected, actual)
        expected.bytesize == actual.bytesize && OpenSSL.fixed_length_secure_compare(expected, actual)
      end

      def parse(body)
        raise InvalidEvent, "webhook body exceeds 1 MiB" if body.bytesize > 1_048_576
        JSON.parse(body)
      rescue JSON::ParserError
        raise InvalidEvent, 'invalid JSON'
      end

      def transmit(**payload)
        raise ArgumentError, 'delivery transport is required' unless @transport
        @transport.call(**payload)
      end
    end
  end
end
