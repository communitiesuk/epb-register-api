namespace :data_export do
  desc "Add hashed assessment_is to the hashed_assessment_id column in the assessments table"

  task :add_hashed_assessment_id, %i[date_from date_to assessment_type] do |_, args|
    date_from = args.date_from
    date_to =   args.date_to
    assessment_type = args.assessment_type

    raise Boundary::ArgumentMissing, "date_from" unless date_from
    raise Boundary::ArgumentMissing, "date_to" unless date_to
    raise Boundary::InvalidDates unless date_from <= date_to
    raise Boundary::ArgumentMissing, "assessment_type, eg: 'SAP-RDSAP', 'DEC' etc" unless assessment_type

    ActiveRecord::Base.logger = nil
    select_bindings = [
      ActiveRecord::Relation::QueryAttribute.new(
        "date_from",
        date_from,
        ActiveRecord::Type::Date.new,
      ),
      ActiveRecord::Relation::QueryAttribute.new(
        "date_to",
        date_to,
        ActiveRecord::Type::Date.new,
      ),
      ActiveRecord::Relation::QueryAttribute.new(
        "type_of_assessment",
        assessment_type,
        ActiveRecord::Type::String.new,
      ),
    ]

    select_sql = <<~SQL
      SELECT assessment_id FROM assessments schemes
      WHERE (date_registered BETWEEN $1 AND $2)
      AND type_of_assessment = $3
    SQL
    assessment_ids = ActiveRecord::Base.connection.exec_query(select_sql, "SQL", select_bindings)
    assessment_ids.map do |assessment_id|
      hashed_assessment_id_data = Helper::RrnHelper.hash_rrn(assessment_id["assessment_id"])

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
        ),
      ]

      sql = <<~SQL
        UPDATE assessments SET hashed_assessment_id = $1 WHERE assessment_id =  $2
      SQL

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
    end
  end
end
