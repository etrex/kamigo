class AddMembershipObservationTime < ActiveRecord::Migration[8.1]
  def change
    add_column :kamigo_conversations, :bot_left_at, :datetime
    add_column :kamigo_memberships, :observed_at, :datetime
  end
end
