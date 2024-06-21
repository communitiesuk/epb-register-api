namespace :maintenance do
  desc "Link non domestic "
  task :bulk_link_assessments do
    use_case = ApiFactory.bulk_link_assessments_use_case
    use_case.execute
  end
end
