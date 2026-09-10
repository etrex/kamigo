# frozen_string_literal: true
module Kamigo
  module Identity
    class Error < StandardError; end
    class VerificationFailed < Error; end
    class AlreadyLinked < Error; end
    class RecoveryRequired < Error; end
    class NotOwner < Error; end

    # Returned by a trusted verifier, NEVER constructed from controller parameters.
    # scope is the platform's identity namespace (provider/tenant/workspace).
    VerifiedIdentity = Data.define(:provider, :scope, :subject, :login_capable)

    class Service
      # verifier.verify(credentials) must validate signature, issuer, audience,
      # expiry and replay protection as appropriate, then return VerifiedIdentity.
      # recovery_available runs under the principal lock. Its credential mutations
      # MUST acquire that same lock, so a concurrent removal cannot bypass safety.
      def initialize(verifier:, recovery_available: ->(_principal) { false })
        @verifier = verifier
        @recovery_available = recovery_available
      end

      def create_principal!
        Principal.create!
      end

      # Lookup is not authentication. The caller must first verify the platform
      # event; provider/scope/subject from an untrusted request prove nothing.
      def resolve(provider:, scope:, subject:)
        ExternalAccount.find_by(provider: provider, scope: scope, subject: subject)&.principal
      end

      def attach!(principal:, credentials:)
        identity = @verifier.verify(credentials)
        unless identity.is_a?(VerifiedIdentity) && [identity.provider, identity.scope, identity.subject].all? { |v| v.is_a?(String) && !v.empty? } && [true, false].include?(identity.login_capable)
          raise VerificationFailed, 'Verifier did not return a verified identity'
        end
        key = { provider: identity.provider, scope: identity.scope, subject: identity.subject }
        principal.with_lock do
          account = ExternalAccount.lock.find_by(key)
          if account && account.principal_id && account.principal_id != principal.id
            raise AlreadyLinked, 'Account belongs to another principal; an explicit merge is required'
          end
          account ||= ExternalAccount.new(key)
          account.assign_attributes(principal: principal, login_capable: account.login_capable || identity.login_capable, linked_at: Time.current)
          account.save!
          account
        end
      rescue ActiveRecord::RecordNotUnique
        # Concurrent claims from separate principals cannot both win. Do not
        # retry by reassigning the winning row to the losing caller.
        raise AlreadyLinked, 'Account was linked concurrently; authenticate again'
      end

      def detach!(principal:, external_account:)
        principal.with_lock do
          account = ExternalAccount.lock.find(external_account.id)
          raise NotOwner, 'Account does not belong to this principal' unless account.principal_id == principal.id
          other_login = ExternalAccount.where(principal_id: principal.id, login_capable: true).where.not(id: account.id).exists?
          unless other_login || @recovery_available.call(principal)
            raise RecoveryRequired, 'An independent login/recovery method is required before unlinking'
          end
          account.update!(principal: nil, linked_at: nil, login_capable: false)
          account
        end
      end
    end
  end
end
