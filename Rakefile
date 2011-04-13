require 'bundler'
Bundler::GemHelper.install_tasks
require 'rake/testtask'
require 'rake/rdoctask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end