# frozen_string_literal: true
require "active_record"
module Kamigo
  module Reliability
    class Receipt < ActiveRecord::Base
      self.table_name = "kamigo_event_receipts"
    end
    class Outbox < ActiveRecord::Base
      self.table_name = "kamigo_outbox"
      ACTIVE_STATES = %w[pending sending].freeze
      TERMINAL_STATES = %w[sent uncertain].freeze

      def self.enqueue!(platform:, connection:, conversation_id:, messages:, delivery_options: {})
        transaction do
          serialize_stream!(platform, connection, conversation_id)
          has_head = where(platform: platform, connection: connection, conversation_id: conversation_id, stream_head: true).exists?
          create!(platform: platform, connection: connection, conversation_id: conversation_id,
            messages: messages, delivery_options: delivery_options, state: "pending", stream_head: !has_head)
        end
      end

      def self.finalize_delivery!(id, state:)
        raise ArgumentError, "invalid terminal state" unless TERMINAL_STATES.include?(state)
        snapshot = find_by(id: id)
        return false unless snapshot
        transaction do
          serialize_stream!(snapshot.platform, snapshot.connection, snapshot.conversation_id)
          row = lock.find_by(id: id, platform: snapshot.platform, connection: snapshot.connection, conversation_id: snapshot.conversation_id)
          next false unless row&.state == "sending"
          was_head = row.stream_head?
          row.update!(state: state, stream_head: false)
          promote_stream!(row.platform, row.connection, row.conversation_id) if was_head
          true
        end
      end

      def self.recover_stale_sending!(before:, limit:)
        relation = where(state: "sending").where("updated_at < ?", before).order(:updated_at, :id)
        maintain_by_stream(relation, limit) do |rows, _stream|
          rows.each do |row|
            was_head = row.stream_head?
            row.update!(state: "uncertain", stream_head: false)
            promote_stream!(row.platform, row.connection, row.conversation_id) if was_head
          end
          rows.length
        end
      end

      def self.expire_stale_pending!(before:, limit:)
        relation = where(state: "pending").where("created_at < ?", before).order(:created_at, :id)
        maintain_by_stream(relation, limit) do |rows, _stream|
          removed_heads = rows.select(&:stream_head?).map { |row| [row.platform, row.connection, row.conversation_id] }.uniq
          where(id: rows.map(&:id)).delete_all
          removed_heads.each { |platform, connection_name, conversation_id| promote_stream!(platform, connection_name, conversation_id) }
          rows.length
        end
      end

      def self.delete_stale_terminal!(before:, limit:)
        limit = normalize_limit(limit)
        transaction do
          relation = where(state: TERMINAL_STATES).where("created_at < ?", before).order(:created_at, :id)
          relation = relation.lock("FOR UPDATE SKIP LOCKED") if connection.adapter_name == "PostgreSQL"
          relation = relation.lock unless connection.adapter_name == "PostgreSQL"
          rows = relation.limit(limit).to_a
          next 0 if rows.empty?
          where(id: rows.map(&:id)).delete_all
        end
      end

      def self.serialize_stream!(platform, connection_name, conversation_id)
        return unless connection.adapter_name == "PostgreSQL"
        stream = [platform, connection_name, conversation_id].map(&:to_s).join("\u001F")
        quoted = connection.quote(stream)
        connection.execute("SELECT pg_advisory_xact_lock(hashtextextended(#{quoted}, 0))")
      end

      def self.try_serialize_stream!(platform, connection_name, conversation_id)
        return true unless connection.adapter_name == "PostgreSQL"
        stream = [platform, connection_name, conversation_id].map(&:to_s).join("\u001F")
        quoted = connection.quote(stream)
        connection.select_value("SELECT pg_try_advisory_xact_lock(hashtextextended(#{quoted}, 0))")
      end

      def self.maintain_by_stream(relation, limit)
        limit = normalize_limit(limit)
        streams = relation.limit(limit).pluck(:platform, :connection, :conversation_id).uniq
        affected = 0
        streams.each do |platform, connection_name, conversation_id|
          break if affected >= limit
          affected += transaction do
            next 0 unless try_serialize_stream!(platform, connection_name, conversation_id)
            rows = relation.where(platform: platform, connection: connection_name, conversation_id: conversation_id)
            rows = rows.lock("FOR UPDATE SKIP LOCKED") if connection.adapter_name == "PostgreSQL"
            rows = rows.lock unless connection.adapter_name == "PostgreSQL"
            rows = rows.limit(limit - affected).to_a
            next 0 if rows.empty?
            yield rows, [platform, connection_name, conversation_id]
          end
        end
        affected
      end

      def self.normalize_limit(value)
        limit = Integer(value)
        raise ArgumentError, "limit must be positive" unless limit.positive?
        limit
      end

      def self.promote_stream!(platform, connection_name, conversation_id)
        next_row = where(platform: platform, connection: connection_name, conversation_id: conversation_id, state: ACTIVE_STATES).order(:id).first
        next_row&.update_columns(stream_head: true)
      end

      private_class_method :serialize_stream!, :try_serialize_stream!, :maintain_by_stream, :normalize_limit, :promote_stream!
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
                delivery_options: (event.platform == "line" && event.payload["replyToken"] ? {reply_token: event.payload["replyToken"]} : {}))
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
        Outbox.where(state: "pending", stream_head: true).order(:id).limit(limit).pluck(:id)
      end

      def initialize(adapter_resolver:, acknowledger: nil)
        @adapter_resolver, @acknowledger = adapter_resolver, acknowledger
      end
      def call(id)
        row = Outbox.find_by(id: id)
        return :not_pending unless row
        claim = begin
          row.with_lock do
            if row.state != "pending"
              :not_pending
            elsif !row.stream_head?
              :blocked
            else
              row.update!(state: "sending")
              :claimed
            end
          end
        rescue ActiveRecord::RecordNotFound
          :not_pending
        end
        return claim unless claim == :claimed
        begin
          adapter = @adapter_resolver.call(row.platform, row.connection)
          messages = row.messages.map { |message| message.deep_symbolize_keys }
          acknowledged_indexes = {}
          result = adapter.deliver(conversation_id: row.conversation_id, messages: messages, **row.delivery_options.deep_symbolize_keys) do |acknowledgment|
            acknowledge(row, messages, acknowledgment, acknowledged_indexes)
          end
          acknowledge(row, messages, { message_indexes: (0...messages.length).to_a, provider_receipt: result }, acknowledged_indexes)
          Outbox.finalize_delivery!(row.id, state: "sent") ? :sent : :uncertain
        rescue StandardError
          Outbox.finalize_delivery!(row.id, state: "uncertain")
          raise
        end
      end

      private

      # Adapters acknowledge only provider-confirmed messages. The fallback
      # after a successful return keeps existing third-party adapters working.
      # Duplicate acknowledgements are collapsed before invoking the host.
      def acknowledge(row, messages, acknowledgment, acknowledged_indexes)
        return unless @acknowledger
        raise TypeError, "delivery acknowledgement must be a hash" unless acknowledgment.is_a?(Hash)
        indexes = acknowledgment[:message_indexes] || acknowledgment["message_indexes"]
        raise TypeError, "delivery acknowledgement indexes must be an array" unless indexes.is_a?(Array)
        indexes = indexes.map do |index|
          value = Integer(index)
          raise IndexError, "delivery acknowledgement index is out of bounds" unless value.between?(0, messages.length - 1)
          value
        rescue ArgumentError, TypeError
          raise TypeError, "delivery acknowledgement index must be an integer"
        end
        indexes = indexes.uniq.reject { |index| acknowledged_indexes[index] }
        return if indexes.empty?
        @acknowledger.call(
          outbox_id: row.id, platform: row.platform, connection: row.connection,
          conversation_id: row.conversation_id, messages: indexes.map { |index| messages.fetch(index) },
          message_indexes: indexes,
          provider_receipt: acknowledgment[:provider_receipt] || acknowledgment["provider_receipt"]
        )
        indexes.each { |index| acknowledged_indexes[index] = true }
      end
    end
  end
end
