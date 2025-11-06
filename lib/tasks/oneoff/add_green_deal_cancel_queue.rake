namespace :oneoff do
  desc "Add all green deal assessments to the cancel queue"
  task :add_green_deal_cancel_queue do
    sql = <<-SQL
        SELECT assessment_id FROM green_deal_assessments
    SQL

    use_case = UseCase::NotifyAssessmentStatusUpdateToDataWarehouse.new(redis_gateway: ApiFactory.data_warehouse_queues_gateway)

    assessment_ids = ActiveRecord::Base.connection.exec_query(sql, "SQL").map { |row| row["assessment_id"] }
    assessment_ids.each do |assessment_id|
      use_case.execute(assessment_id:)
    end
    num_assessments = assessment_ids.length

    puts "pushed #{num_assessments} assessments to the cancelled queue"
  end
end
