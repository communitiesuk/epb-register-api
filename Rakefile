require "sinatra"
require "sinatra/activerecord"
require "sinatra/activerecord/rake"
Dir.glob("lib/tasks/*.rake").each { |r| load r }

namespace :tasks do
  desc "Run all tasks in lib/tasks"
  task all: %i[import_postcode import_postcode_outcode generate_schemes generate_assessor generate_certificate]
end
