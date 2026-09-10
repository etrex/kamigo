# frozen_string_literal: true
require 'tmpdir'
require 'fileutils'
require 'etc'
require 'socket'
require 'open3'
require 'json'
require 'rbconfig'

root = File.expand_path('../..', __dir__)
bundle = File.join(root, 'Gemfile')
directory = Dir.mktmpdir('kamigo-pg-host-', '/tmp')
data = File.join(directory, 'data')
log = File.join(directory, 'postgres.log')
probe = TCPServer.new('127.0.0.1', 0)
port = probe.addr[1]
probe.close
binary = ENV.fetch('PG_BIN', '/opt/homebrew/opt/postgresql@15/bin')
pg_environment = ENV.keys.grep(/^PG/).to_h { |key| [key, nil] }
run_pg = lambda do |command, *arguments|
  output, status = Open3.capture2e(pg_environment, File.join(binary, command), *arguments)
  abort output unless status.success?
end
started = false

begin
  run_pg.call('initdb', '-D', data, '-A', 'trust', '--encoding=UTF8', '--no-locale')
  run_pg.call('pg_ctl', '-D', data, '-l', log, '-o', "-p #{port} -c listen_addresses='127.0.0.1'", '-w', 'start')
  started = true

  host = File.join(directory, 'host')
  environment = {
    'BUNDLE_GEMFILE' => bundle,
    'RAILS_ENV' => 'development',
    'PATH' => "#{File.dirname(RbConfig.ruby)}:#{ENV.fetch('PATH')}",
    'DATABASE_URL' => "postgresql://#{Etc.getpwuid.name}@127.0.0.1:#{port}/postgres"
  }
  create = [
    RbConfig.ruby, '-S', 'bundle', 'exec', 'rails', 'new', host,
    '--database=postgresql', '--skip-bundle', '--skip-git', '--skip-test',
    '--skip-system-test', '--skip-javascript', '--skip-asset-pipeline',
    '--skip-action-mailer', '--skip-action-mailbox', '--skip-action-text',
    '--skip-active-storage', '--skip-solid', '--skip-bootsnap'
  ]
  output, status = Open3.capture2e(environment, *create, chdir: directory)
  abort output unless status.success?
  output, status = Open3.capture2e(environment, RbConfig.ruby, File.join(host, 'bin/rails'), 'generate', 'kamigo:install', chdir: host)
  abort output unless status.success?
  output, status = Open3.capture2e(environment, RbConfig.ruby, File.join(host, 'bin/rails'), 'db:migrate', chdir: host)
  abort output unless status.success?

  expression = <<~'RUBY'
    require 'securerandom'
    require 'kamigo/conversations'
    principal = Kamigo::Identity::Principal.create!(public_id: SecureRandom.uuid)
    identity = Kamigo::Identity::ExternalAccount.create!(
      principal: principal, provider: 'line', scope: 'acceptance',
      subject: 'pg-host-user', login_capable: true, linked_at: Time.current
    )
    conversation = Kamigo::Conversations::Conversation.create!(
      provider: 'line', scope: 'acceptance', subject: 'pg-host-group',
      bot_joined_at: Time.current
    )
    membership = Kamigo::Conversations::Membership.create!(
      conversation: conversation, principal: principal, role: 'admin',
      observed_at: Time.current
    )
    receipt = Kamigo::Reliability::Receipt.create!(
      platform: 'line', connection: 'acceptance', event_id: 'pg-host-event',
      created_at: Time.current
    )
    outbox = Kamigo::Reliability::Outbox.create!(
      platform: 'line', connection: 'acceptance', conversation_id: 'pg-host-group',
      messages: [{type: 'text', text: 'ok'}], delivery_options: {}, state: 'pending'
    )
    invalid_role_rejected = begin
      ActiveRecord::Base.connection.execute(
        "INSERT INTO kamigo_memberships(conversation_id,principal_id,role,created_at,updated_at) VALUES(#{conversation.id},#{principal.id},'owner',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"
      )
      false
    rescue ActiveRecord::StatementInvalid
      true
    end
    invalid_identity_rejected = begin
      ActiveRecord::Base.connection.execute(
        "INSERT INTO kamigo_external_accounts(provider,scope,subject,login_capable,created_at,updated_at) VALUES('','','',FALSE,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"
      )
      false
    rescue ActiveRecord::StatementInvalid
      true
    end
    puts JSON.generate(
      adapter: ActiveRecord::Base.connection.adapter_name,
      tables: %w[kamigo_principals kamigo_external_accounts kamigo_conversations kamigo_memberships kamigo_event_receipts kamigo_outbox].to_h { |name| [name, ActiveRecord::Base.connection.data_source_exists?(name)] },
      stream_order_index: ActiveRecord::Base.connection.indexes('kamigo_outbox').any? { |index| index.name == 'kamigo_outbox_stream_state_order' },
      principal: principal.persisted?, identity: identity.persisted?,
      conversation: conversation.persisted?, membership: membership.persisted?,
      receipt: receipt.persisted?, outbox: outbox.persisted?,
      invalid_role_rejected: invalid_role_rejected,
      invalid_identity_rejected: invalid_identity_rejected,
      initializer: Rails.root.join('config/initializers/kamigo.rb').exist?
    )
  RUBY
  output, status = Open3.capture2e(environment, RbConfig.ruby, File.join(host, 'bin/rails'), 'runner', expression, chdir: host)
  abort output unless status.success?
  result = JSON.parse(output.lines.last)
  expected_tables = result.fetch('tables').values.all?
  expected_records = %w[principal identity conversation membership receipt outbox].all? { |key| result[key] }
  abort result.inspect unless result['adapter'] == 'PostgreSQL' && expected_tables && expected_records && result['stream_order_index'] && result['invalid_role_rejected'] && result['invalid_identity_rejected'] && result['initializer']
  puts JSON.generate(result.merge('migrations' => Dir[File.join(host, 'db/migrate', '*.rb')].size))
ensure
  run_pg.call('pg_ctl', '-D', data, '-m', 'fast', '-w', 'stop') if started
  FileUtils.remove_entry(directory) if File.exist?(directory)
end
