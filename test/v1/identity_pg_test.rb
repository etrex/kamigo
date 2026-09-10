# frozen_string_literal: true
# Standalone integration test. Creates and destroys its own Unix-socket-only PG
# cluster; never reads DATABASE_URL or connects to an existing PostgreSQL server.
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'etc'
require_relative '../../lib/kamigo/identity'
require_relative '../../db/migrate/20260909000001_create_kamigo_identity'

class IdentityPostgresTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir('kamigo-identity-', '/tmp')
    @bin = ENV.fetch('PG_BIN', '/opt/homebrew/opt/postgresql@15/bin')
    @env = ENV.keys.grep(/^PG/).to_h { |key| [key, nil] }
    run_pg('initdb', '-D', "#{@directory}/data", '-A', 'trust', '--encoding=UTF8', '--no-locale')
    run_pg('pg_ctl', '-D', "#{@directory}/data", '-l', "#{@directory}/postgres.log", '-o', "-k #{@directory} -p 55449 -c listen_addresses=''", '-w', 'start')
    @started = true
    ActiveRecord::Base.establish_connection(adapter: 'postgresql', host: @directory, port: 55449,
      database: 'postgres', username: Etc.getpwuid.name, pool: 8, checkout_timeout: 5)
    ActiveRecord::Migration.verbose = false
    CreateKamigoIdentity.new.change
  end

  def teardown
    ActiveRecord::Base.connection_pool.disconnect!
    run_pg('pg_ctl', '-D', "#{@directory}/data", '-m', 'fast', '-w', 'stop') if @started
    FileUtils.remove_entry(@directory) if @directory && File.exist?(@directory)
  end

  def test_competing_principals_can_never_both_claim_account
    principals = 2.times.map { Kamigo::Identity::Principal.create! }
    ready, proceed, outcomes = Queue.new, Queue.new, Queue.new
    verifier = Object.new
    verifier.define_singleton_method(:verify) do |_credentials|
      ready << true
      proceed.pop
      Kamigo::Identity::VerifiedIdentity.new(provider: 'line', scope: 'p1', subject: 'same-user', login_capable: true)
    end
    threads = principals.map do |principal|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          service = Kamigo::Identity::Service.new(verifier: verifier)
          begin
            service.attach!(principal: principal, credentials: 'adapter-verifies-this')
            outcomes << :linked
          rescue Kamigo::Identity::AlreadyLinked
            outcomes << :conflict
          rescue StandardError => e
            outcomes << e
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { proceed << true }
    threads.each(&:join)
    results = 2.times.map { outcomes.pop }
    assert_equal [:conflict, :linked], results.sort_by(&:to_s), results.inspect
    assert_equal 1, Kamigo::Identity::ExternalAccount.count
    assert_includes principals.map(&:id), Kamigo::Identity::ExternalAccount.first.principal_id
  end

  def test_concurrent_unlinks_keep_one_login
    principal = Kamigo::Identity::Principal.create!
    verifier = Object.new
    verifier.define_singleton_method(:verify) do |subject|
      Kamigo::Identity::VerifiedIdentity.new(provider: 'line', scope: 'p1', subject: subject, login_capable: true)
    end
    service = Kamigo::Identity::Service.new(verifier: verifier)
    accounts = %w[a b].map { |subject| service.attach!(principal: principal, credentials: subject) }
    ready, proceed, outcomes = Queue.new, Queue.new, Queue.new
    threads = accounts.map do |account|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          own_principal = Kamigo::Identity::Principal.find(principal.id)
          ready << true
          proceed.pop
          begin
            service.detach!(principal: own_principal, external_account: account)
            outcomes << :unlinked
          rescue Kamigo::Identity::RecoveryRequired
            outcomes << :protected
          rescue StandardError => e
            outcomes << e
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { proceed << true }
    threads.each(&:join)
    results = 2.times.map { outcomes.pop }
    assert_equal [:protected, :unlinked], results.sort_by(&:to_s), results.inspect
    assert_equal 1, Kamigo::Identity::ExternalAccount.where(principal_id: principal.id, login_capable: true).count
  end

  private

  def run_pg(command, *args)
    success = system(@env, File.join(@bin, command), *args, out: File::NULL, err: File::NULL)
    raise "Isolated PostgreSQL #{command} failed" unless success
  end
end
