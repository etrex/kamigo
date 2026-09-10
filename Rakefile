require "bundler/setup"
require "rake/testtask"
require "bundler/gem_tasks"
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.pattern = "test/v1/**/*_test.rb"
end
task default: :test
