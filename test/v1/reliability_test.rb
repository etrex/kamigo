# frozen_string_literal: true
require 'minitest/autorun'
require 'active_support/core_ext/hash/keys'
require_relative '../../lib/kamigo/event'
require_relative '../../lib/kamigo/reliability'
require_relative '../../db/migrate/20260909000002_create_kamigo_delivery'

class ReliabilityTest < Minitest::Test
  class BusinessRecord < ActiveRecord::Base
    self.table_name = 'test_business_records'
  end

  def setup
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Migration.verbose = false
    CreateKamigoDelivery.new.change
    ActiveRecord::Base.connection.create_table(:test_business_records) { |t| t.string :value }
    BusinessRecord.reset_column_information
    @event = Kamigo::Event.new(platform: 'line', connection: 'main', id: 'event-1', actor_id: 'user', conversation_id: 'group', type: :message)
  end

  def receiver(&handler)
    dispatcher = Object.new
    dispatcher.define_singleton_method(:call, &handler)
    Kamigo::Reliability::Receiver.new(adapter: nil, dispatcher: dispatcher, context_resolver: ->(_event) { Kamigo::Context.new(principal_id: 1) })
  end

  def test_duplicate_receipt_runs_business_once_and_enqueues_once
    target = receiver do |_event, context:|
      BusinessRecord.create!(value: context.principal_id.to_s)
      [{ type: 'text', text: 'hello' }]
    end
    assert_equal :processed, target.process(@event)
    assert_equal :duplicate, target.process(@event)
    assert_equal 1, BusinessRecord.count
    assert_equal 1, Kamigo::Reliability::Receipt.count
    assert_equal 1, Kamigo::Reliability::Outbox.count
  end

  def test_failure_rolls_back_receipt_business_and_outbox_then_retry_succeeds
    target = receiver do |_event, context:|
      BusinessRecord.create!(value: 'tentative')
      Kamigo::Reliability::Outbox.create!(platform: 'line', connection: 'main', conversation_id: 'group', messages: [], state: 'pending')
      raise 'business failed'
    end
    assert_raises(RuntimeError) { target.process(@event) }
    assert_equal 0, BusinessRecord.count
    assert_equal 0, Kamigo::Reliability::Receipt.count
    assert_equal 0, Kamigo::Reliability::Outbox.count
    assert_equal :processed, receiver { |_event, context:| [] }.process(@event)
  end

  def test_receipt_identity_is_scoped_by_connection
    target = receiver { |_event, context:| [] }
    assert_equal :processed, target.process(@event)
    assert_equal :processed, target.process(@event.with(connection: 'other'))
    assert_equal 2, Kamigo::Reliability::Receipt.count
  end

  def test_line_reply_token_is_preserved_through_outbox
    target = receiver { |_event, context:| [{ type: 'text', text: 'hello' }] }
    assert_equal :processed, target.process(@event.with(payload: { 'replyToken' => 'verified-token' }))
    row = Kamigo::Reliability::Outbox.first
    captured = nil
    adapter = Object.new
    adapter.define_singleton_method(:deliver) { |**args| captured = args }
    delivery = Kamigo::Reliability::Delivery.new(adapter_resolver: ->(*) { adapter })
    assert_equal :sent, delivery.call(row.id)
    assert_equal 'verified-token', captured[:reply_token]
  end

  def test_successful_delivery_is_not_repeated
    row = new_outbox
    sent = []
    adapter = Object.new
    adapter.define_singleton_method(:deliver) { |**args| sent << args }
    delivery = Kamigo::Reliability::Delivery.new(adapter_resolver: ->(*) { adapter })
    assert_equal :sent, delivery.call(row.id)
    assert_equal :not_pending, delivery.call(row.id)
    assert_equal 1, sent.size
    assert_equal 'sent', row.reload.state
    assert_equal [{ type: 'text', text: 'hello' }], sent.first[:messages]
  end

  def test_unknown_network_outcome_is_not_automatically_replayed
    row = new_outbox
    attempts = 0
    adapter = Object.new
    adapter.define_singleton_method(:deliver) do |**|
      attempts += 1
      raise IOError, 'connection closed after remote may have accepted message'
    end
    delivery = Kamigo::Reliability::Delivery.new(adapter_resolver: ->(*) { adapter })
    assert_raises(IOError) { delivery.call(row.id) }
    assert_equal 'uncertain', row.reload.state
    assert_equal :not_pending, delivery.call(row.id)
    assert_equal 1, attempts
  end

  def test_interrupted_sending_is_not_replayed
    row = new_outbox
    row.update!(state: 'sending')
    delivery = Kamigo::Reliability::Delivery.new(adapter_resolver: ->(*) { raise 'must not deliver' })
    assert_equal :not_pending, delivery.call(row.id)
  end

  private

  def new_outbox
    Kamigo::Reliability::Outbox.create!(platform: 'line', connection: 'main', conversation_id: 'group',
      messages: [{ type: 'text', text: 'hello' }], state: 'pending')
  end
end
