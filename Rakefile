require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'rdoc/task'

desc 'Default: run unit tests.'
task :default => :test

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--colour"
end

Rake::TestTask.new(:testunit) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Regentanz'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :test => [:testunit, :spec]
