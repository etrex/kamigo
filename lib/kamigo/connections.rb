# frozen_string_literal: true

module Kamigo
  module Connections
    class UnknownConnection < KeyError; end
    class InvalidConnection < ArgumentError; end

    Definition = Data.define(:platform, :connection, :identity_scope, :conversation_scope, :adapter) do
      def initialize(platform:, connection:, identity_scope:, conversation_scope: connection, adapter:)
        values = [platform, connection, identity_scope, conversation_scope]
        raise InvalidConnection, "connection identity must not be empty" if values.any? { |value| value.to_s.empty? }
        unless adapter.respond_to?(:events) && adapter.respond_to?(:deliver)
          raise InvalidConnection, "connection adapter must receive events and deliver messages"
        end

        super(platform: platform.to_s.freeze, connection: connection.to_s.freeze,
          identity_scope: identity_scope.to_s.freeze, conversation_scope: conversation_scope.to_s.freeze,
          adapter: adapter)
      end
    end

    class Registry
      def initialize(&resolver)
        raise ArgumentError, "connection resolver is required" unless resolver

        @resolver = resolver
      end

      def resolve(platform:, connection:)
        platform = platform.to_s
        connection = connection.to_s
        raise UnknownConnection, "unknown connection" if platform.empty? || connection.empty?

        value = @resolver.call(platform: platform, connection: connection)
        raise UnknownConnection, "unknown #{platform} connection: #{connection}" unless value

        definition = value.is_a?(Definition) ? value : Definition.new(**value)
        unless definition.platform == platform && definition.connection == connection
          raise InvalidConnection, "resolved connection identity does not match the request"
        end

        definition
      end
    end
  end

  class << self
    attr_writer :connections

    def connections
      @connections ||= Connections::Registry.new { nil }
    end
  end
end
