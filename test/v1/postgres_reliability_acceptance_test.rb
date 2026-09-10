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
    assert_equal 107,result['outboxes']
    assert_equal 1,result['delivery_attempts']
    assert_equal 'sent',result['state']
    assert_equal %w[sent blocked sent],result['ordered_results']
    assert_equal %w[first second],result['ordered_messages']
    assert_equal true,result['uncommitted_blocked']
    assert_equal ['race first','race second'],result['race_messages']
    assert_equal true,result['fair_ready']
  end
end
