# frozen_string_literal: true
require 'minitest/autorun'
require 'open3'
require 'json'
require 'rbconfig'

class PostgresReliabilityAcceptanceTest < Minitest::Test
  def test_concurrent_receipt_and_delivery_are_single_effect_on_postgres
    root=File.expand_path('../..',__dir__)
    output,status=Open3.capture2e(RbConfig.ruby,File.join(root,'script/acceptance/postgres_reliability.rb'),chdir:root)
    assert status.success?,output
    result=JSON.parse(output.lines.last)
    assert_equal 1,result['receipts']
    assert_equal 1,result['business_effects']
    assert_equal 1_000_009,result['outboxes']
    assert_equal 1,result['delivery_attempts']
    assert_equal 'sent',result['state']
    assert_equal %w[sent blocked sent],result['ordered_results']
    assert_equal %w[first second],result['ordered_messages']
    assert_equal true,result['advisory_wait_observed']
    assert_equal true,result['uncommitted_blocked']
    assert_equal ['race first','race second'],result['race_messages']
    assert_equal true,result['upgrade_quarantine']
    assert_equal true,result['maintenance']
    assert_equal [1000,1000,501],result['expiry_batches']
    assert_equal true,result['fair_ready']
    assert_equal 1_000_000,result['fair_backlog']
    assert_equal true,result['ready_index_used']
    assert_operator result['ready_execution_ms'],:<,250
  end
end
