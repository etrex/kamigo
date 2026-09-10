# frozen_string_literal: true
require 'minitest/autorun'
require 'open3'
require 'json'
require 'rbconfig'

class HostInstallTest < Minitest::Test
  def test_fresh_rails_host_installs_migrates_and_boots_engine
    root = File.expand_path('../..', __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, File.join(root,'script/acceptance/host_install.rb'), chdir: root)
    assert status.success?, output
    result = JSON.parse(output.lines.last)
    assert_equal 'kamigo', result['engine']
    assert_equal true, result['principal']
    assert_equal true, result['conversations']
    assert_equal true, result['receipts']
    assert_equal true, result['initializer']
    assert_equal 5, result['migrations']
  end
end
