# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Open a console with the gem loaded"
task :console do
  require "irb"
  require "ruby_slm"
  ARGV.clear
  IRB.start
end