# frozen_string_literal: true
require "active_record"
module Kamigo
  module Reliability
    class Receipt < ActiveRecord::Base
      self.table_name = "kamigo_event_receipts"
    end
    class Outbox < ActiveRecord::Base
      self.table_name = "kamigo_outbox"

      def self.enqueue!(platform:, connection:, conversation_id:, messages:, delivery_options: {}, state: "pending")
        transaction do
          serialize_stream!(platform, connection, conversation_id)
          create!(platform: platform, connection: connection, conversation_id: conversation_id,
            messages: messages, delivery_options: delivery_options, state: state)
        end
      end

      def self.serialize_stream!(platform, connection_name, conversation_id)
        return unless connection.adapter_name == "PostgreSQL"
        stream = [platform, connection_name, conversation_id].map(&:to_s).join("\u001F")
        quoted = connection.quote(stream)
        connection.execute("SELECT pg_advisory_xact_lock(hashtextextended(#{quoted}, 0))")
      end
      private_class_method :serialize_stream!
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
              Outbox.enqueue!(platform: event.platform, connection: event.connection,
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
      def self.ready_ids(limit:)
        limit = Integer(limit)
        raise ArgumentError, "limit must be positive" unless limit.positive?
        table = Outbox.connection.quote_table_name(Outbox.table_name)
        # Return only the oldest pending row in each unblocked conversation.
        # This prevents a busy or stalled conversation from consuming a global
        # worker batch while preserving creation order inside that conversation.
        unblocked = <<~SQL.squish
          NOT EXISTS (
            SELECT 1 FROM #{table} AS kamigo_earlier_outbox
            WHERE kamigo_earlier_outbox.platform = #{table}.platform
              AND kamigo_earlier_outbox.connection = #{table}.connection
              AND kamigo_earlier_outbox.conversation_id = #{table}.conversation_id
              AND kamigo_earlier_outbox.id < #{table}.id
              AND kamigo_earlier_outbox.state IN ('pending', 'sending')
          )
        SQL
        Outbox.where(state: "pending").where(unblocked).order(:id).limit(limit).pluck(:id)
      rescue ArgumentError, TypeError
        raise ArgumentError, "limit must be positive"
      end

      def initialize(adapter_resolver:)
        @adapter_resolver = adapter_resolver
      end
      def call(id)
        row = Outbox.find(id)
        claim = row.with_lock do
          if row.state != "pending"
            :not_pending
          elsif Outbox.where(platform: row.platform, connection: row.connection, conversation_id: row.conversation_id)
              .where('id < ?', row.id).where(state: %w[pending sending]).exists?
            # Keep replies for one conversation in creation order even when
            # several deployment workers selected adjacent rows together.
            # The caller can retry this still-pending row on its next drain.
            :blocked
          else
            row.update!(state: "sending")
            :claimed
          end
        end
        return claim unless claim == :claimed
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
