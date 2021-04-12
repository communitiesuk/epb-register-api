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

namespace :tasks do
  desc "Run all tasks in lib/tasks"
  task all: %i[import_postcode import_postcode_outcode generate_schemes generate_assessor]
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end
