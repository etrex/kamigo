# frozen_string_literal: true
require 'minitest/autorun'
require_relative '../../lib/kamigo/identity'
require_relative '../../db/migrate/20260909000001_create_kamigo_identity'

class IdentityTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Migration.verbose = false
    CreateKamigoIdentity.new.change
    @principal = Kamigo::Identity::Principal.create!
    @other = Kamigo::Identity::Principal.create!
    @identity = Kamigo::Identity::VerifiedIdentity.new(provider: 'line', scope: 'provider-1', subject: 'user-1', login_capable: true)
    @verifier = Object.new
    @verifier.define_singleton_method(:verify) { |_credentials| @result }
    @verifier.instance_variable_set(:@result, @identity)
    @service = Kamigo::Identity::Service.new(verifier: @verifier)
  end

  def test_explicit_verified_link_and_conflicting_claim
    account = @service.attach!(principal: @principal, credentials: 'verified by adapter')
    assert_equal @principal, @service.resolve(provider: 'line', scope: 'provider-1', subject: 'user-1')
    assert_equal account.id, @service.attach!(principal: @principal, credentials: 'new verification').id
    assert_raises(Kamigo::Identity::AlreadyLinked) { @service.attach!(principal: @other, credentials: 'proof') }
    assert_equal @principal.id, account.reload.principal_id
  end

  def test_scoped_uniqueness_and_case_sensitive_subjects
    @service.attach!(principal: @principal, credentials: 'proof')
    @verifier.instance_variable_set(:@result, @identity.with(scope: 'provider-2'))
    @service.attach!(principal: @other, credentials: 'proof')
    @verifier.instance_variable_set(:@result, @identity.with(subject: 'USER-1'))
    @service.attach!(principal: @other, credentials: 'proof')
    assert_equal 3, Kamigo::Identity::ExternalAccount.count
  end

  def test_database_rejects_duplicate_identity_without_service
    account = @service.attach!(principal: @principal, credentials: 'proof')
    assert_raises(ActiveRecord::RecordNotUnique) do
      Kamigo::Identity::ExternalAccount.create!(provider: account.provider, scope: account.scope, subject: account.subject,
        principal: @other, linked_at: Time.current, login_capable: true)
    end
  end

  def test_other_verified_login_allows_detach_without_recovery
    first = @service.attach!(principal: @principal, credentials: 'proof')
    @verifier.instance_variable_set(:@result, @identity.with(provider: 'telegram', scope: 'global'))
    second = @service.attach!(principal: @principal, credentials: 'proof')
    @service.detach!(principal: @principal, external_account: first)
    assert_equal @principal.id, second.reload.principal_id
    assert_raises(Kamigo::Identity::RecoveryRequired) { @service.detach!(principal: @principal, external_account: second) }
  end

  def test_client_hash_is_not_verification
    @verifier.instance_variable_set(:@result, { provider: 'line', subject: 'user', verified: true })
    assert_raises(Kamigo::Identity::VerificationFailed) { @service.attach!(principal: @principal, credentials: 'claim') }
    assert_equal 0, Kamigo::Identity::ExternalAccount.count
  end

  def test_last_login_is_protected_and_recovery_allows_detach
    account = @service.attach!(principal: @principal, credentials: 'proof')
    assert_raises(Kamigo::Identity::RecoveryRequired) { @service.detach!(principal: @principal, external_account: account) }
    assert_raises(Kamigo::Identity::NotOwner) { @service.detach!(principal: @other, external_account: account) }
    recovery_service = Kamigo::Identity::Service.new(verifier: @verifier, recovery_available: ->(p) { p.id == @principal.id })
    recovery_service.detach!(principal: @principal, external_account: account)
    assert_nil account.reload.principal_id
    assert_nil @service.resolve(provider: 'line', scope: 'provider-1', subject: 'user-1')
    assert_equal @principal.public_id, @principal.reload.public_id
  end
end
