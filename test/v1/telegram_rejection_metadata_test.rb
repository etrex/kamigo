require 'minitest/autorun'
require_relative '../../lib/kamigo/platforms/http_transport'

class TelegramRejectionMetadataTest < Minitest::Test
  def test_diagnostics_allowlist_and_migration_boundaries
    error = Kamigo::Platforms::DeliveryRejected.new(status: 400, reason: 'SECRET', migrate_to_chat_id: 'SECRET')
    assert_nil error.reason
    assert_nil error.migrate_to_chat_id
    refute_includes error.inspect, 'SECRET'
    [-1, -(2**52) + 1].each do |id|
      assert_equal id, Kamigo::Platforms::DeliveryRejected.new(migrate_to_chat_id: id).migrate_to_chat_id
    end
    [0, 1, -(2**52), -1.0].each do |id|
      assert_nil Kamigo::Platforms::DeliveryRejected.new(migrate_to_chat_id: id).migrate_to_chat_id
    end
  end

  def test_rate_limited_error_preserves_retry_contract
    error = Kamigo::Platforms::DeliveryRateLimited.new(retry_after: 792, reason: 'other')
    assert_kind_of Kamigo::Platforms::DeliveryRejected, error
    assert_equal 429, error.status
    assert_equal 792, error.retry_after
    assert_equal 'other', error.reason
    assert_raises(ArgumentError) { Kamigo::Platforms::DeliveryRateLimited.new(retry_after: 0) }
  end
end
