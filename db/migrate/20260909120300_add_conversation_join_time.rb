class AddConversationJoinTime < ActiveRecord::Migration[8.1]
  def change
    add_column :kamigo_conversations, :bot_joined_at, :datetime
  end
end
