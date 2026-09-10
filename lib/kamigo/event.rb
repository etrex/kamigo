# frozen_string_literal: true
module Kamigo
  module Immutable
    def self.copy(value)
      case value
      when Hash then value.to_h { |k, v| [copy(k), copy(v)] }.freeze
      when Array then value.map { |v| copy(v) }.freeze
      when String then value.dup.freeze
      when Symbol, Numeric, NilClass, TrueClass, FalseClass then value
      else raise ArgumentError, "unsupported context value: #{value.class}"
      end
    end
  end

  Event = Data.define(:platform, :connection, :id, :actor_id, :conversation_id, :type, :text, :payload) do
    def initialize(platform:, connection:, id:, actor_id:, conversation_id:, type:, text: nil, payload: {})
      raise ArgumentError, "event identity required" if [platform, connection, id, conversation_id, type].any? { |v| v.nil? || v.to_s.empty? }
      raise ArgumentError, "text must be a String" unless text.nil? || text.is_a?(String)
      super(**{platform: platform.to_s, connection: connection.to_s, id: id.to_s,
        actor_id: actor_id&.to_s, conversation_id: conversation_id.to_s,
        type: type.to_sym, text: text, payload: payload}.transform_values { |v| Immutable.copy(v) })
    end
  end

  Context = Data.define(:principal_id, :roles, :attributes) do
    def initialize(principal_id: nil, roles: [], attributes: {})
      super(principal_id: Immutable.copy(principal_id), roles: Immutable.copy(roles), attributes: Immutable.copy(attributes))
    end
  end
end
