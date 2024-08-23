# select all private subnets when running the task in the console to update the data warehouse
namespace :maintenance do
  desc "Link non domestic "
  task :bulk_link_assessments do
    use_case = ApiFactory.bulk_link_assessments_use_case
    use_case.execute
  end
end
