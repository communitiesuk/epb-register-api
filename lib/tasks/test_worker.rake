# This task exists to test the Sidekiq integration - please leave it alone :)
task :test_worker do
  use_case = UseCase::FetchSchemes.new
  pp use_case.execute
end
