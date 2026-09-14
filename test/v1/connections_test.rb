require 'minitest/autorun'
require_relative '../../lib/kamigo/connections'

class ConnectionsTest < Minitest::Test
  class Adapter
    def events(**); end
    def deliver(**); end
  end

  def test_resolves_and_normalizes_a_connection_definition
    registry = Kamigo::Connections::Registry.new do |platform:, connection:|
      {platform: platform, connection: connection, identity_scope: 'provider-1', adapter: Adapter.new}
    end

    definition = registry.resolve(platform: :line, connection: :primary)

    assert_equal 'line', definition.platform
    assert_equal 'primary', definition.connection
    assert_equal 'provider-1', definition.identity_scope
    assert_kind_of Adapter, definition.adapter
  end

  def test_unknown_and_mismatched_connections_fail_closed
    missing = Kamigo::Connections::Registry.new { nil }
    assert_raises(Kamigo::Connections::UnknownConnection) do
      missing.resolve(platform: :line, connection: :missing)
    end

    mismatched = Kamigo::Connections::Registry.new do
      {platform: 'line', connection: 'different', identity_scope: 'provider-1', adapter: Adapter.new}
    end
    assert_raises(Kamigo::Connections::InvalidConnection) do
      mismatched.resolve(platform: :line, connection: :requested)
    end
  end

  def test_definition_requires_a_complete_identity_and_platform_adapter
    assert_raises(Kamigo::Connections::InvalidConnection) do
      Kamigo::Connections::Definition.new(platform: :line, connection: '', identity_scope: 'provider-1', adapter: Adapter.new)
    end
    assert_raises(Kamigo::Connections::InvalidConnection) do
      Kamigo::Connections::Definition.new(platform: :line, connection: 'primary', identity_scope: 'provider-1', adapter: Object.new)
    end
  end
end
