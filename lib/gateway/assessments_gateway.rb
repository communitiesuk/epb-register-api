# frozen_string_literal: true

module Gateway
  class AssessmentsGateway
    include ReadOnlyDatabaseAccess

    class Assessment < ActiveRecord::Base; end

    class AssessmentScotland < ActiveRecord::Base
      self.table_name = "scotland.assessments"
    end

    class InvalidAssessmentType < StandardError; end

    class AssessmentAlreadyExists < StandardError; end

    VALID_ASSESSMENT_TYPES = %w[
      RdSAP
      SAP
      CEPC
      CEPC-RR
      DEC
      DEC-RR
      AC-CERT
      AC-REPORT
    ].freeze

    def insert_or_update(assessment, is_scottish: false)
      check_valid_energy_ratings assessment
      send_update_to_db(assessment, is_scottish)
    end

    def insert(assessment)
      check_valid_energy_ratings assessment
      send_insert_to_db assessment
    end

    def update_statuses(assessments_ids, status, value)
      ActiveRecord::Base.transaction do
        assessments_ids.each do |assessment_id|
          update_field(assessment_id, status, value)
        end
      end
    end

    def update_field(assessment_id, field, value)
      sql =
        "UPDATE assessments SET #{ActiveRecord::Base.connection.quote_column_name(field)} = #{ActiveRecord::Base.connection.quote(value)} WHERE assessment_id = #{ActiveRecord::Base.connection.quote(assessment_id)}"

      Assessment.connection.exec_query(sql)
    end

    def get_linked_assessment_id(assessment_id)
      select_linked_assessment = <<-SQL
            SELECT linked_assessment_id FROM linked_assessments
            WHERE assessment_id = $1
      SQL
      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
      ]
      result =
        ActiveRecord::Base.connection.exec_query select_linked_assessment,
                                                 "SQL",
                                                 binds
      result.first["linked_assessment_id"] unless result.empty?
    end

    def fetch_assessment_ids_by_range(date_from, date_to = Time.now)
      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          date_from,
          ActiveRecord::Type::Date.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          date_to,
          ActiveRecord::Type::Date.new,
        ),
      ]

      sql = <<-SQL
           SELECT assessment_id, type_of_assessment
            FROM assessments a
           WHERE a.date_registered BETWEEN $1 AND $2
      SQL

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
    end

    def fetch_assessments_by_date(date:, assessment_types: nil)
      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date",
          date,
          ActiveRecord::Type::String.new,
        ),
      ]

      sql = <<-SQL
           SELECT assessment_id, type_of_assessment, ae.registered_by AS scheme_id, current_energy_efficiency_rating,
             CASE WHEN a.postcode LIKE 'BT%' THEN 'Northern Ireland' ELSE 'England & Wales' END AS country
             FROM assessments a
           JOIN assessors ae ON a.scheme_assessor_id = ae.scheme_assessor_id
           WHERE to_char(created_at, 'YYYY-MM-DD') = $1 AND migrated IS NOT TRUE
      SQL

      if assessment_types.is_a?(Array)
        invalid_types = assessment_types - VALID_ASSESSMENT_TYPES
        raise StandardError, "Invalid types" unless invalid_types.empty?

        list_of_types = assessment_types.map { |n| "'#{n}'" }
        sql += <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment IN(#{list_of_types.join(',')})
        SQL_TYPE_OF_ASSESSMENT
      end

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
    end

    def fetch_assessment_id_by_date_and_type(date_from:, date_to:, assessment_types: nil)
      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          date_from,
          ActiveRecord::Type::Date.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          date_to,
          ActiveRecord::Type::Date.new,
        ),
      ]

      sql = <<-SQL
        SELECT assessment_id
        FROM assessments a
        WHERE a.date_registered BETWEEN $1 AND $2
        AND NOT EXISTS(SELECT * FROM assessments_country_ids ac WHERE a.assessment_id = ac.assessment_id)
      SQL

      if assessment_types.is_a?(Array)
        invalid_types = assessment_types - VALID_ASSESSMENT_TYPES
        raise StandardError, "Invalid types" unless invalid_types.empty?

        list_of_types = assessment_types.map { |n| "'#{n}'" }
        sql += <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment IN(#{list_of_types.join(',')})
        SQL_TYPE_OF_ASSESSMENT
      end

      result = []
      read_only do
        result = ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
      end

      result.map { |row| row["assessment_id"] }
    end

    def fetch_location_by_assessment_id(assessment_id)
      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      sql = <<-SQL
           SELECT a.assessment_id, a.postcode, a.address_id, x.xml, x.schema_type
            FROM assessments a
            JOIN assessments_xml x ON x.assessment_id = a.assessment_id
           WHERE a.assessment_id = $1
      SQL

      result = {}
      read_only do
        result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      end

      result.first
    end

    def update_created_at_from_landmark?(assessment_id, created_at)
      return false if created_at < "2006-01-01" || created_at > "2020-10-01"

      sql = <<-SQL
        UPDATE assessments
        SET created_at = $1
        WHERE assessment_id = $2 AND migrated = TRUE
        RETURNING TRUE AS updated
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date",
          created_at,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      !ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).rows.empty?
    end

  private

    def send_insert_to_db(assessment)
      ActiveRecord::Base.transaction do
        begin
          Assessment.create assessment.to_record
        rescue ActiveRecord::RecordNotUnique
          raise AssessmentAlreadyExists
        end

        unless assessment.get(:related_rrn).nil?
          add_linked_assessment(assessment, 'public.')
        end
      end
    end

    def send_update_to_db(assessment, is_scottish)
      ActiveRecord::Base.transaction do
        existing_assessment = if is_scottish
                                AssessmentScotland.exists?(assessment_id: assessment.get(:assessment_id))
                              else
                                Assessment.exists?(assessment_id: assessment.get(:assessment_id))
                              end

        if existing_assessment
          schema = is_scottish ? "scotland." : "public."
          remove_and_relodge_assessment(assessment, schema)
        else
          is_scottish ? AssessmentScotland.create(assessment.to_record) : Assessment.create(assessment.to_record)
        end

        unless assessment.get(:related_rrn).nil?
          add_linked_assessment(assessment, schema)
        end
      end
    end

    def remove_and_relodge_assessment(assessment, schema)
      delete_xml = <<-SQL
            DELETE FROM #{schema}assessments_xml WHERE assessment_id = $1
      SQL

      delete_address_id = <<-SQL
            DELETE FROM #{schema}assessments_address_id WHERE assessment_id = $1
      SQL

      green_deal_plan_id = <<-SQL
            SELECT green_deal_plan_id FROM #{schema}green_deal_assessments WHERE assessment_id = $1
      SQL

      delete_green_deal_assessment = <<-SQL
            DELETE FROM #{schema}green_deal_assessments WHERE assessment_id = $1
      SQL

      delete_assessment = <<-SQL
            DELETE FROM #{schema}assessments WHERE assessment_id = $1
      SQL

      delete_linked_assessment = <<-SQL
            DELETE FROM #{schema}linked_assessments WHERE assessment_id = $1
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "id",
          assessment.get(:assessment_id),
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query delete_xml, "SQL", binds

      green_deal_plan_ids =
        ActiveRecord::Base.connection.exec_query green_deal_plan_id,
                                                 "SQL",
                                                 binds

      ActiveRecord::Base.connection.exec_query delete_green_deal_assessment,
                                               "SQL",
                                               binds

      ActiveRecord::Base.connection.exec_query delete_assessment,
                                               "SQL",
                                               binds

      ActiveRecord::Base.connection.exec_query delete_address_id,
                                               "SQL",
                                               binds

      ActiveRecord::Base.connection.exec_query delete_linked_assessment,
                                               "SQL",
                                               binds

      if schema == "scotland."
        AssessmentScotland.create assessment.to_record
      else
        Assessment.create assessment.to_record
      end

      #TODO Need to test this
      reattach_green_deal_plans(green_deal_plan_ids, binds, schema)
    end

    def check_valid_energy_ratings(assessment)
      if %w[CEPC RdSAP SAP].include? assessment.get(:type_of_assessment)
        current = assessment.get(:current_energy_efficiency_rating)

        unless current.is_a? Integer
          raise ArgumentError, "Invalid current energy rating"
        end

        if %w[RdSAP SAP].include? assessment.get(:type_of_assessment)
          unless current.positive?
            raise ArgumentError, "Invalid current energy rating"
          end

          potential = assessment.get(:potential_energy_efficiency_rating)

          unless potential.is_a?(Integer) && potential.positive?
            raise ArgumentError, "Invalid potential energy rating"
          end
        end
      end
    end

    def reattach_green_deal_plans(green_deal_plan_ids, binds, schema)
      add_green_deal_plan = <<-SQL
            INSERT INTO #{schema}green_deal_assessments (assessment_id, green_deal_plan_id)
            VALUES ($1, $2)
      SQL

      green_deal_plan_ids.map do |result|
        inner_bind = binds
        inner_bind <<
          ActiveRecord::Relation::QueryAttribute.new(
            "green_deal_plan_id",
            result["green_deal_plan_id"],
            ActiveRecord::Type::String.new,
          )

        ActiveRecord::Base.connection.exec_query add_green_deal_plan,
                                                 "SQL",
                                                 inner_bind
      end
    end

    def add_linked_assessment(assessment, schema)
      add_linked_assessment = <<-SQL
            INSERT INTO #{schema}linked_assessments (assessment_id, linked_assessment_id)
            VALUES ($1, $2)
      SQL

      linked_assessment_binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment.get(:assessment_id),
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "linked_assessment_id",
          assessment.get(:related_rrn),
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query add_linked_assessment,
                                               "SQL",
                                               linked_assessment_binds
    end
  end
end
