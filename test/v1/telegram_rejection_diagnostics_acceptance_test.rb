require 'minitest/autorun'
require 'open3'
require 'json'

class TelegramRejectionDiagnosticsAcceptanceTest < Minitest::Test
  # Manual TGD-1: same public HTTP scenario and independent local fixture.
  def test_safe_provider_diagnostics
    output, status = Open3.capture2e(RbConfig.ruby, File.expand_path('../../script/acceptance/telegram_rejection_diagnostics.rb', __dir__))
    assert status.success?, output
    rows = output.lines.map { |line| JSON.parse(line) }
    assert_equal %w[chat_not_found migrated_chat bot_blocked not_member message_too_long invalid_entities slow_mode other other other other], rows.map { |row| row.fetch('reason') }
    assert_equal [400, 400, 403, 403, 400, 400, 429, 429, 400, 400, 400], rows.map { |row| row.fetch('status') }
    assert_equal(-100123, rows[1]['migrate_to_chat_id'])
    assert_nil rows.last['migrate_to_chat_id']
    assert_equal 12, rows[6]['retry_after']
    assert_equal 792, rows[7]['retry_after']
    refute_includes output, 'SECRET'
  end
end
