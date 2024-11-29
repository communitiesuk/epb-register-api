module Gateway
  class AssessmentsCountryIdGateway
    class AssessmentsCountryId < ActiveRecord::Base
    end

    def insert(assessment_id:, country_id:, upsert: false)
      sql = if upsert
              <<-SQL
        INSERT INTO assessments_country_ids (assessment_id,country_id) VALUES ($1, $2)
           ON CONFLICT(assessment_id)
        DO UPDATE SET country_id=$2
              SQL
            else
              <<-SQL
        INSERT INTO assessments_country_ids (assessment_id,country_id) VALUES ($1, $2)
              SQL
            end

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "country_id",
          country_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
      end
    rescue ActiveRecord::RecordNotUnique
      raise Gateway::AssessmentsGateway::AssessmentAlreadyExists
    end

    def fetch(assessment_id)
      sql = <<-SQL
        SELECT
        country_id AS country_id
        FROM assessments_country_ids
        WHERE assessment_id = $1
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).first
    end

    def fetch_country_name(assessment_id)
      sql = <<-SQL
        SELECT
        country_name AS country_name
        FROM assessments_country_ids
        JOIN countries on assessments_country_ids.country_id = countries.country_id
        WHERE assessment_id = $1
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
          ),
      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).first
    end

  rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionFailed
    raise
  end
end
