require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

# Load all rake tasks from lib/tasks
Dir.glob('lib/tasks/*.rake').each { |r| load r }

task default: :spec