# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task :lint do
  puts "Running StandardRB..."
  Rake::Task["standard"].invoke
  puts "StandardRB passed."
end

task default: %i[spec lint]
