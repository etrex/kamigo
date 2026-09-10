# frozen_string_literal: true

require 'minitest/autorun'
require 'active_record'
require_relative '../../lib/kamigo/reliability'
require_relative '../../db/migrate/20260909000002_create_kamigo_delivery'
require_relative '../../db/migrate/20260910000001_add_kamigo_outbox_stream_heads'

class OutboxStreamHeadUpgradeTest < Minitest::Test
  def test_upgrade_accepts_a_host_installed_before_the_stream_order_index_existed
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Migration.verbose = false
    CreateKamigoDelivery.new.change
    ActiveRecord::Base.connection.remove_index(:kamigo_outbox, name: 'kamigo_outbox_stream_state_order')

    first = Kamigo::Reliability::Outbox.create!(
      platform: 'line', connection: 'main', conversation_id: 'group',
      messages: [{ type: 'text', text: 'first' }], delivery_options: {}, state: 'pending'
    )
    second = Kamigo::Reliability::Outbox.create!(
      platform: 'line', connection: 'main', conversation_id: 'group',
      messages: [{ type: 'text', text: 'second' }], delivery_options: {}, state: 'pending'
    )

    AddKamigoOutboxStreamHeads.new.up
    Kamigo::Reliability::Outbox.reset_column_information

    assert first.reload.stream_head?
    refute second.reload.stream_head?
    assert_equal [first.id], Kamigo::Reliability::Delivery.ready_ids(limit: 10)
  ensure
    ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
  end
end
