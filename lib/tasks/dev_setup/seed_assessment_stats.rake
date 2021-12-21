namespace :dev_data do
  desc "seed assessment_statistics table with the fixture data"
  task :seed_assessment_stats do
    Rake::Task["dev_data:lodge_dev_assessments"].execute

    ActiveRecord::Base.connection.exec_query("UPDATE assessments SET created_at = current_date - INTEGER '1' ")

    ActiveRecord::Base.connection.exec_query("TRUNCATE assessment_statistics")

    Rake::Task["maintenance:daily_statistics"].execute
  end

  desc "generates some fake assessment statistics for last 2 months"
  task :generate_fake_stats do
    ActiveRecord::Base.connection.exec_query("TRUNCATE assessment_statistics")
    gateway = Gateway::AssessmentStatisticsGateway.new

    61.times do |i|
      date = Time.now.to_date - (i + 1).days
      gateway.save(assessment_type: "RdSAP", assessments_count: rand(50..90), rating_average: rand(10..92), day_date: date, transaction_type: rand(1..6), country: "England & Wales")
      gateway.save(assessment_type: "SAP", assessments_count: rand(50..90), rating_average: rand(10..92), day_date: date, transaction_type: rand(1..6), country: "Northern Ireland")
    end

    puts "Generated statistics for the last 2 months"
  end
end
