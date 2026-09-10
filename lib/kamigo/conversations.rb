# frozen_string_literal: true
require 'active_record'
module Kamigo
  module Conversations
    class Conversation < ActiveRecord::Base
      self.table_name = 'kamigo_conversations'
      validates :provider, :scope, :subject, presence: true
      attr_readonly :provider, :scope, :subject
      has_many :memberships, class_name: 'Kamigo::Conversations::Membership', foreign_key: :conversation_id
    end
    class Membership < ActiveRecord::Base
      self.table_name = 'kamigo_memberships'
      belongs_to :conversation, class_name: 'Kamigo::Conversations::Conversation'
      belongs_to :principal, class_name: 'Kamigo::Identity::Principal'
      validates :role, inclusion: { in: %w[member admin] }
      scope :active, -> { where(left_at: nil) }
    end
  end
end
