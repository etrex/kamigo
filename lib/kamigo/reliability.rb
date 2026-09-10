# frozen_string_literal: true
require "active_record"
module Kamigo
  module Reliability
    class Receipt < ActiveRecord::Base
      self.table_name = "kamigo_event_receipts"
    end
    class Outbox < ActiveRecord::Base
      self.table_name = "kamigo_outbox"
    end

    class Receiver
      def initialize(adapter:, dispatcher:, context_resolver:)
        @adapter, @dispatcher, @context_resolver = adapter, dispatcher, context_resolver
      end
      def call(body:, headers:, connection:)
        @adapter.events(body: body, headers: headers, connection: connection).map do |event|
          process(event)
        end
      end
      def process(event)
        result = :duplicate
        Receipt.transaction do
          # Nested savepoint allows PostgreSQL uniqueness failure without aborting business transaction.
          receipt = begin
            Receipt.transaction(requires_new: true) do
              Receipt.create!(platform: event.platform, connection: event.connection, event_id: event.id)
            end
          rescue ActiveRecord::RecordNotUnique
            nil
          end
          if receipt
            context = @context_resolver.call(event)
            raise TypeError, "resolver must return Kamigo::Context" unless context.is_a?(Context)
            messages = @dispatcher.call(event, context: context)
            if messages && !messages.empty?
              Outbox.create!(platform: event.platform, connection: event.connection,
                conversation_id: event.conversation_id, messages: messages,
                delivery_options: (event.platform == "line" && event.payload["replyToken"] ? {reply_token: event.payload["replyToken"]} : {}), state: "pending")
            end
            result = :processed
          end
        end
        result
      end
    end

    # An interrupted/failed send is uncertain, never automatically replayed.
    # A delivery worker can reconcile using provider idempotency/status capabilities.
    class Delivery
      def initialize(adapter_resolver:)
        @adapter_resolver = adapter_resolver
      end
      def call(id)
        row = Outbox.find(id)
        claimed = row.with_lock do
          if row.state == "pending"
            row.update!(state: "sending")
            true
          else
            false
          end
        end
        return :not_pending unless claimed
        begin
          adapter = @adapter_resolver.call(row.platform, row.connection)
          adapter.deliver(conversation_id: row.conversation_id, messages: row.messages.map { |message| message.deep_symbolize_keys }, **row.delivery_options.deep_symbolize_keys)
          row.update!(state: "sent")
          :sent
        rescue StandardError
          row.update!(state: "uncertain")
          raise
        end
      end
    end
  end
end
