# This task exists to test the Sidekiq integration - please leave it alone :)
desc "a test worker"
task :test_worker do
  use_case = UseCase::FetchSchemes.new
  pp use_case.execute
end
