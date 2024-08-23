# select all private subnets (but not the private-db subnets) when running the task in the console to ensure data warehouse is updated
namespace :maintenance do
  desc "Link non domestic "
  task :bulk_link_assessments do
    use_case = ApiFactory.bulk_link_assessments_use_case
    use_case.execute
  end
end
