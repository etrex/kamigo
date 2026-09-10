class CreateKamigoDelivery < ActiveRecord::Migration[8.1]
  def change
    create_table :kamigo_event_receipts do |t|
      t.string :platform, null: false
      t.string :connection, null: false
      t.string :event_id, null: false
      t.datetime :created_at, null: false
    end
    add_index :kamigo_event_receipts, [:platform, :connection, :event_id], unique: true, name: "kamigo_receipt_identity"
    add_index :kamigo_event_receipts, :created_at
    create_table :kamigo_outbox do |t|
      t.string :platform, null: false
      t.string :connection, null: false
      t.string :conversation_id, null: false
      t.json :messages, null: false
      t.json :delivery_options, null: false, default: {}
      t.string :state, null: false, default: "pending"
      t.timestamps
    end
    add_check_constraint :kamigo_outbox, "state IN ('pending','sending','sent','uncertain')", name: "kamigo_outbox_state"
    add_index :kamigo_outbox, [:state, :id]
  end
end
