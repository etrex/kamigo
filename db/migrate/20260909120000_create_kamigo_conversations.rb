class CreateKamigoConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :kamigo_conversations do |t|
      t.string :provider, null: false
      t.string :scope, null: false
      t.string :subject, null: false
      t.timestamps
    end
    add_index :kamigo_conversations, [:provider, :scope, :subject], unique: true
    create_table :kamigo_memberships do |t|
      t.references :conversation, null: false, foreign_key: {to_table: :kamigo_conversations}
      t.references :principal, null: false, foreign_key: {to_table: :kamigo_principals}
      t.string :role, null: false, default: 'member'
      t.datetime :left_at
      t.timestamps
    end
    add_index :kamigo_memberships, [:conversation_id, :principal_id], unique: true
    add_check_constraint :kamigo_memberships, "role IN ('member', 'admin')", name: 'membership_role'
  end
end
