# frozen_string_literal: true
require 'minitest/autorun'
require 'open3'
require 'json'
require 'rbconfig'

class PostgresHostInstallTest < Minitest::Test
  def test_fresh_postgres_host_runs_every_generated_migration_and_boots_models
    root = File.expand_path('../..', __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, File.join(root, 'script/acceptance/postgres_host_install.rb'), chdir: root)
    assert status.success?, output
    result = JSON.parse(output.lines.last)
    assert_equal 'PostgreSQL', result.fetch('adapter')
    assert_equal 6, result.fetch('migrations')
    assert result.fetch('tables').values.all?, result.fetch('tables').inspect
    %w[principal identity conversation membership receipt outbox].each do |record|
      assert_equal true, result.fetch(record), record
    end
    assert_equal true, result.fetch('invalid_role_rejected')
    assert_equal true, result.fetch('invalid_identity_rejected')
    assert_equal true, result.fetch('invalid_head_rejected')
    assert result.fetch('stream_indexes').values.all?, result.fetch('stream_indexes').inspect
    assert_equal true, result.fetch('initializer')
  end
end
