namespace :oneoff do
  desc "deletes all reloads assessment statistics data"
  task :reload_assessment_statistics do
    use_case = ApiFactory.reload_assessment_statistics_use_case
    use_case.execute
  end
end
