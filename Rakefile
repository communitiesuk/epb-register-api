require 'sinatra/activerecord'
require 'sinatra'
require 'sinatra/activerecord/rake'
Dir.glob('lib/tasks/*.rake').each { |r| load r}

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

namespace :cf do
  desc "Only run on the first application instance"
  task :on_first_instance do
    instance_index = JSON.parse(ENV["VCAP_APPLICATION"])["instance_index"] rescue nil
    exit(0) unless instance_index == 0
  end
end
