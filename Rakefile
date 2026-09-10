require "bundler/setup"
require "rake/testtask"
require "bundler/gem_tasks"
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end
task default: :test
