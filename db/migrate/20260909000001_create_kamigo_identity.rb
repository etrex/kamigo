# frozen_string_literal: true
class CreateKamigoIdentity < ActiveRecord::Migration[8.0]
  def change
    create_table :kamigo_principals do |t|
      t.string :public_id, null: false, limit: 36
      t.timestamps
    end
    add_index :kamigo_principals, :public_id, unique: true

    create_table :kamigo_external_accounts do |t|
      t.references :principal, foreign_key: { to_table: :kamigo_principals }
      # Platform IDs are opaque and case-sensitive. PostgreSQL C collation
      # prevents database locale choices from changing identity equality.
      options = connection.adapter_name == 'PostgreSQL' ? { collation: 'C' } : {}
      t.string :provider, null: false, limit: 64, **options
      t.string :scope, null: false, limit: 255, **options
      t.string :subject, null: false, limit: 255, **options
      t.boolean :login_capable, null: false, default: false
      t.datetime :linked_at
      t.timestamps
    end
    add_index :kamigo_external_accounts, [:provider, :scope, :subject], unique: true, name: 'kamigo_external_identity_unique'
    add_check_constraint :kamigo_external_accounts, "provider <> '' AND scope <> '' AND subject <> ''", name: 'kamigo_identity_not_empty'
    add_check_constraint :kamigo_external_accounts, '(principal_id IS NULL AND linked_at IS NULL AND login_capable = FALSE) OR (principal_id IS NOT NULL AND linked_at IS NOT NULL)', name: 'kamigo_identity_link_consistent'
  end
end
