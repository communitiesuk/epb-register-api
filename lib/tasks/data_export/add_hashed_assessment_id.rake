namespace :data_export do
  desc 'Add hashed assessment_is to the hashed_assessment_id column in the assessments table'

  task :add_hashed_assessment_id do
    ActiveRecord::Base.logger = nil
    select_query = "SELECT assessment_id FROM assessments schemes"
    assessment_ids = ActiveRecord::Base.connection.exec_query(select_query)
    assessment_ids.map do |assessment_id|
      hashed_assessment_id_data = Helper::RrnHelper.hash_rrn(assessment_id['assessment_id'])

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "hashed_assessment_id",
          hashed_assessment_id_data,
          ActiveRecord::Type::String.new,
          ),

        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id["assessment_id"],
          ActiveRecord::Type::String.new,
          )
      ]

      sql = <<~SQL
        UPDATE assessments SET hashed_assessment_id = $1 WHERE assessment_id =  $2
      SQL

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
    end
  end
end
