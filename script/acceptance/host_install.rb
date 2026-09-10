# frozen_string_literal: true
require 'tmpdir'
require 'open3'
require 'json'
require 'rbconfig'

root = File.expand_path('../..', __dir__)
bundle = File.join(root, 'Gemfile')
Dir.mktmpdir('kamigo-host-', '/tmp') do |directory|
  host = File.join(directory, 'host')
  environment = {'BUNDLE_GEMFILE'=>bundle, 'RAILS_ENV'=>'development', 'PATH'=>"#{File.dirname(RbConfig.ruby)}:#{ENV.fetch('PATH')}"}
  create = [RbConfig.ruby, '-S', 'bundle', 'exec', 'rails', 'new', host, '--skip-bundle', '--skip-git', '--skip-test', '--skip-system-test', '--skip-javascript', '--skip-asset-pipeline', '--skip-action-mailer', '--skip-action-mailbox', '--skip-action-text', '--skip-active-storage', '--skip-solid', '--skip-bootsnap']
  output, status = Open3.capture2e(environment, *create, chdir: directory)
  abort output unless status.success?
  output, status = Open3.capture2e(environment, RbConfig.ruby, File.join(host,'bin/rails'), 'generate', 'kamigo:install', chdir: host)
  abort output unless status.success?
  output, status = Open3.capture2e(environment, RbConfig.ruby, File.join(host,'bin/rails'), 'db:migrate', chdir: host)
  abort output unless status.success?
  expression = <<~'RUBY'
    puts JSON.generate(
      engine: Kamigo::Engine.engine_name,
      principal: ActiveRecord::Base.connection.data_source_exists?('kamigo_principals'),
      conversations: ActiveRecord::Base.connection.data_source_exists?('kamigo_conversations'),
      receipts: ActiveRecord::Base.connection.data_source_exists?('kamigo_event_receipts'),
      initializer: Rails.root.join('config/initializers/kamigo.rb').exist?
    )
  RUBY
  output, status = Open3.capture2e(environment, RbConfig.ruby, File.join(host,'bin/rails'), 'runner', expression, chdir: host)
  abort output unless status.success?
  result = JSON.parse(output.lines.last)
  expected = {'engine'=>'kamigo','principal'=>true,'conversations'=>true,'receipts'=>true,'initializer'=>true}
  abort result.inspect unless result == expected
  puts JSON.generate(result.merge('migrations'=>Dir[File.join(host,'db/migrate','*.rb')].size))
end
