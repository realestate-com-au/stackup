# frozen_string_literal: true

require "rspec/core/rake_task"
require "rubocop/rake_task"

task :default => %i[spec rubocop]

RSpec::Core::RakeTask.new do |task|
  task.pattern = FileList["spec/**/*_spec.rb"]
end

RuboCop::RakeTask.new
