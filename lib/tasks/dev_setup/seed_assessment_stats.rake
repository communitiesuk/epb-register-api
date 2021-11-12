namespace :dev_data do
  desc "seed assessment_statistics table with the fixture data"
  task :seed_assessment_stats do
    Rake::Task["dev_data:lodge_dev_assessments"].execute

    ActiveRecord::Base.connection.exec_query("UPDATE assessments SET created_at = current_date - INTEGER '1' ")

    ActiveRecord::Base.connection.exec_query("TRUNCATE assessment_statistics")

    Rake::Task["maintenance:daily_statistics"].execute
  end
end
