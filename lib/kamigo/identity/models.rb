# frozen_string_literal: true
module Kamigo
  module Identity
    class Principal < ActiveRecord::Base
      self.table_name = 'kamigo_principals'
      attr_readonly :public_id
      has_many :external_accounts, class_name: 'Kamigo::Identity::ExternalAccount', inverse_of: :principal
      before_validation(on: :create) { self.public_id ||= SecureRandom.uuid }
      validates :public_id, presence: true
    end

    class ExternalAccount < ActiveRecord::Base
      self.table_name = 'kamigo_external_accounts'
      attr_readonly :provider, :scope, :subject
      belongs_to :principal, class_name: 'Kamigo::Identity::Principal', optional: true, inverse_of: :external_accounts
      validates :provider, :scope, :subject, presence: true
    end
  end
end
