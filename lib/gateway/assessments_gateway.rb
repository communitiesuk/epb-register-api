# frozen_string_literal: true

module Gateway
  class AssessmentsGateway
    class Assessment < ActiveRecord::Base; end

    class InvalidAssessmentType < StandardError; end

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

    def insert_or_update(assessment)
      check_valid_energy_ratings assessment
      send_to_db assessment
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
           SELECT assessment_id, type_of_assessment, ae.registered_by AS scheme_id, current_energy_efficiency_rating
             FROM assessments a
           JOIN assessors ae on a.scheme_assessor_id = ae.scheme_assessor_id
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

  private

    def send_to_db(assessment)
      ActiveRecord::Base.transaction do
        existing_assessment =
          Assessment.find_by assessment_id: assessment.get(:assessment_id)

        if existing_assessment
          delete_xml = <<-SQL
            DELETE FROM assessments_xml WHERE assessment_id = $1
          SQL

          delete_address_id = <<-SQL
            DELETE FROM assessments_address_id WHERE assessment_id = $1
          SQL

          green_deal_plan_id = <<-SQL
            SELECT green_deal_plan_id FROM green_deal_assessments WHERE assessment_id = $1
          SQL

          delete_green_deal_assessment = <<-SQL
            DELETE FROM green_deal_assessments WHERE assessment_id = $1
          SQL

          delete_assessment = <<-SQL
            DELETE FROM assessments WHERE assessment_id = $1
          SQL

          delete_linked_assessment = <<-SQL
            DELETE FROM linked_assessments WHERE assessment_id = $1
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

          Assessment.create assessment.to_record

          reattach_green_deal_plans(green_deal_plan_ids, binds)
        else
          Assessment.create assessment.to_record
        end

        unless assessment.get(:related_rrn).nil?
          add_linked_assessment assessment
        end
      end
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

    def reattach_green_deal_plans(green_deal_plan_ids, binds)
      add_green_deal_plan = <<-SQL
            INSERT INTO green_deal_assessments (assessment_id, green_deal_plan_id)
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

    def add_linked_assessment(assessment)
      add_linked_assessment = <<-SQL
            INSERT INTO linked_assessments (assessment_id, linked_assessment_id)
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
