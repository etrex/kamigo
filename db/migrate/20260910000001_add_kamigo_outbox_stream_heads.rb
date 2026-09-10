class AddKamigoOutboxStreamHeads < ActiveRecord::Migration[8.1]
  def up
    add_column :kamigo_outbox, :stream_head, :boolean, null: false, default: false
    # A pre-1.0 worker could have left more than one row marked sending in a
    # stream. Keep only the oldest active row eligible and quarantine the rest.
    execute <<~SQL
      UPDATE kamigo_outbox
      SET state = 'uncertain', updated_at = CURRENT_TIMESTAMP
      WHERE state = 'sending'
        AND id NOT IN (
          SELECT MIN(id)
          FROM kamigo_outbox
          WHERE state IN ('pending', 'sending')
          GROUP BY platform, connection, conversation_id
        )
    SQL
    execute <<~SQL
      UPDATE kamigo_outbox
      SET stream_head = TRUE
      WHERE id IN (
        SELECT MIN(id)
        FROM kamigo_outbox
        WHERE state IN ('pending', 'sending')
        GROUP BY platform, connection, conversation_id
      )
    SQL
    add_check_constraint :kamigo_outbox,
      "stream_head = FALSE OR state IN ('pending','sending')",
      name: "kamigo_outbox_head_active"
    add_check_constraint :kamigo_outbox,
      "state <> 'sending' OR stream_head = TRUE",
      name: "kamigo_outbox_sending_is_head"
    remove_index :kamigo_outbox, name: "index_kamigo_outbox_on_state_and_id", if_exists: true
    remove_index :kamigo_outbox, name: "kamigo_outbox_stream_state_order", if_exists: true
    add_index :kamigo_outbox, [:platform, :connection, :conversation_id], unique: true,
      where: "stream_head = TRUE", name: "kamigo_outbox_one_stream_head"
    add_index :kamigo_outbox, :id,
      where: "stream_head = TRUE AND state = 'pending'", name: "kamigo_outbox_ready_heads"
    add_index :kamigo_outbox, [:created_at, :id],
      where: "state = 'pending'", name: "kamigo_outbox_pending_expiry"
    add_index :kamigo_outbox, [:updated_at, :id],
      where: "state = 'sending'", name: "kamigo_outbox_sending_recovery"
    add_index :kamigo_outbox, [:platform, :connection, :conversation_id, :id],
      where: "state IN ('pending','sending')", name: "kamigo_outbox_active_stream_order"
    add_index :kamigo_outbox, [:created_at, :id],
      where: "state IN ('sent','uncertain')", name: "kamigo_outbox_terminal_retention"
    add_index :kamigo_outbox, :id,
      where: "state = 'uncertain'", name: "kamigo_outbox_uncertain_count"
  end

  def down
    remove_index :kamigo_outbox, name: "kamigo_outbox_uncertain_count"
    remove_index :kamigo_outbox, name: "kamigo_outbox_terminal_retention"
    remove_index :kamigo_outbox, name: "kamigo_outbox_active_stream_order"
    remove_index :kamigo_outbox, name: "kamigo_outbox_sending_recovery"
    remove_index :kamigo_outbox, name: "kamigo_outbox_pending_expiry"
    remove_index :kamigo_outbox, name: "kamigo_outbox_ready_heads"
    remove_index :kamigo_outbox, name: "kamigo_outbox_one_stream_head"
    add_index :kamigo_outbox, [:state, :id], if_not_exists: true
    add_index :kamigo_outbox, [:platform, :connection, :conversation_id, :state, :id], name: "kamigo_outbox_stream_state_order", if_not_exists: true
    remove_check_constraint :kamigo_outbox, name: "kamigo_outbox_head_active"
    remove_check_constraint :kamigo_outbox, name: "kamigo_outbox_sending_is_head"
    remove_column :kamigo_outbox, :stream_head
  end
end
