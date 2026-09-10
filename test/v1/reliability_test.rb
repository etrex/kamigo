# frozen_string_literal: true
require 'minitest/autorun'
require 'active_support/core_ext/hash/keys'
require_relative '../../lib/kamigo/event'
require_relative '../../lib/kamigo/reliability'
require_relative '../../db/migrate/20260909000002_create_kamigo_delivery'
require_relative '../../db/migrate/20260910000001_add_kamigo_outbox_stream_heads'

class ReliabilityTest < Minitest::Test
  class BusinessRecord < ActiveRecord::Base
    self.table_name = 'test_business_records'
  end

  def setup
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Migration.verbose = false
    CreateKamigoDelivery.new.change
    AddKamigoOutboxStreamHeads.new.up
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
      Kamigo::Reliability::Outbox.enqueue!(platform: 'line', connection: 'main', conversation_id: 'group', messages: [])
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

  def test_successful_legacy_adapter_falls_back_to_one_complete_acknowledgement
    row = Kamigo::Reliability::Outbox.enqueue!(platform: 'line', connection: 'main', conversation_id: 'group',
      messages: [{ type: 'text', text: 'one' }, { type: 'text', text: 'two' }])
    adapter = Object.new
    adapter.define_singleton_method(:deliver) { |**| { status: 200, request_id: 'request-1' } }
    acknowledgements = []
    delivery = Kamigo::Reliability::Delivery.new(
      adapter_resolver: ->(*) { adapter }, acknowledger: ->(**attributes) { acknowledgements << attributes }
    )

    assert_equal :sent, delivery.call(row.id)
    assert_equal :not_pending, delivery.call(row.id)
    assert_equal 1, acknowledgements.length
    assert_equal [0, 1], acknowledgements.first[:message_indexes]
    assert_equal ['one', 'two'], acknowledgements.first[:messages].map { |message| message[:text] }
    assert_equal row.id, acknowledgements.first[:outbox_id]
  end

  def test_partial_acknowledgement_survives_later_message_failure_without_replay
    row = Kamigo::Reliability::Outbox.enqueue!(platform: 'telegram', connection: 'main', conversation_id: '-20',
      messages: [{ text: 'confirmed' }, { text: 'rejected' }])
    adapter = Object.new
    adapter.define_singleton_method(:deliver) do |**arguments, &acknowledged|
      acknowledged.call(message_indexes: [0], provider_receipt: { message_id: 91 })
      raise IOError, arguments.inspect
    end
    acknowledgements = []
    delivery = Kamigo::Reliability::Delivery.new(
      adapter_resolver: ->(*) { adapter }, acknowledger: ->(**attributes) { acknowledgements << attributes }
    )

    assert_raises(IOError) { delivery.call(row.id) }
    assert_equal 'uncertain', row.reload.state
    assert_equal [[0]], acknowledgements.map { |item| item[:message_indexes] }
    assert_equal ['confirmed'], acknowledgements.first[:messages].map { |message| message[:text] }
    assert_equal :not_pending, delivery.call(row.id)
    assert_equal 1, acknowledgements.length
  end

  def test_duplicate_adapter_acknowledgements_are_collapsed_and_fallback_fills_only_missing_indexes
    row = Kamigo::Reliability::Outbox.enqueue!(platform: 'telegram', connection: 'main', conversation_id: '-21',
      messages: [{ text: 'first' }, { text: 'second' }])
    adapter = Object.new
    adapter.define_singleton_method(:deliver) do |**_, &acknowledged|
      2.times { acknowledged.call(message_indexes: [0], provider_receipt: { message_id: 92 }) }
      { status: 200 }
    end
    acknowledgements = []
    delivery = Kamigo::Reliability::Delivery.new(
      adapter_resolver: ->(*) { adapter }, acknowledger: ->(**attributes) { acknowledgements << attributes }
    )

    assert_equal :sent, delivery.call(row.id)
    assert_equal [[0], [1]], acknowledgements.map { |item| item[:message_indexes] }
    assert_equal ['first', 'second'], acknowledgements.flat_map { |item| item[:messages] }.map { |message| message[:text] }
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

  def test_delivery_promotes_the_next_materialized_stream_head
    first = new_outbox
    second = new_outbox
    assert first.stream_head?
    refute second.stream_head?
    assert_equal [first.id], Kamigo::Reliability::Delivery.ready_ids(limit: 10)
    adapter = Object.new
    adapter.define_singleton_method(:deliver) { |**| { status: 200 } }
    delivery = Kamigo::Reliability::Delivery.new(adapter_resolver: ->(*) { adapter })
    assert_equal :sent, delivery.call(first.id)
    assert second.reload.stream_head?
    assert_equal [second.id], Kamigo::Reliability::Delivery.ready_ids(limit: 10)
  end

  private

  def new_outbox
    Kamigo::Reliability::Outbox.enqueue!(platform: 'line', connection: 'main', conversation_id: 'group',
      messages: [{ type: 'text', text: 'hello' }])
  end
end
