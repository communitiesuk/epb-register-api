require "sinatra"
require "sinatra/activerecord"
require "sinatra/activerecord/rake"

unless defined? Zeitwerk
  require "zeitwerk"
  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/lib/")
  loader.setup
end

Dir.glob("lib/tasks/*.rake").each { |r| load r }
Dir.glob("lib/tasks/*/*.rake").each { |r| load r }

namespace :tasks do
  desc "Run developer data bootstrap tasks in lib/tasks"
  task bootstrap_dev_data: %i[
  dev_data:import_postcode_outcode
  dev_data:generate_schemes
  dev_data:generate_assessors
  dev_data:lodge_dev_assessments
  dev_data:seed_test_green_deal_plans
]
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # just pass through
end
