# frozen_string_literal: true

module Gateway
  class AssessmentsGateway
    class Assessment < ActiveRecord::Base; end

    class InvalidAssessmentType < StandardError; end

    def insert_or_update(assessment)
      check_valid_energy_ratings assessment
      send_to_db assessment
    end

    def update_field(assessment_id, field, value)
      sql =
        "UPDATE assessments SET " +
        ActiveRecord::Base.connection.quote_column_name(field) + " = " +
        ActiveRecord::Base.connection.quote(value) +
        " WHERE assessment_id = " +
        ActiveRecord::Base.connection.quote(assessment_id) + ""

      Assessment.connection.execute(sql)
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

          green_deal_plan_id = <<-SQL
            SELECT green_deal_plan_id FROM green_deal_assessments WHERE assessment_id = $1
          SQL

          delete_green_deal_assessment = <<-SQL
            DELETE FROM green_deal_assessments WHERE assessment_id = $1
          SQL

          delete_assessment = <<-SQL
            DELETE FROM assessments WHERE assessment_id = $1
          SQL

          binds = [
            ActiveRecord::Relation::QueryAttribute.new(
              "id",
              assessment.get(:assessment_id),
              ActiveRecord::Type::String.new,
            ),
          ]

          ActiveRecord::Base.connection.exec_query delete_xml, "SQL", binds

          results =
            ActiveRecord::Base.connection.exec_query green_deal_plan_id,
                                                     "SQL",
                                                     binds

          ActiveRecord::Base.connection.exec_query delete_green_deal_assessment,
                                                   "SQL",
                                                   binds

          ActiveRecord::Base.connection.exec_query delete_assessment,
                                                   "SQL",
                                                   binds

          Assessment.create assessment.to_record

          add_green_deal_plan = <<-SQL
            INSERT INTO green_deal_assessments (assessment_id, green_deal_plan_id)
            VALUES ($1, $2)
          SQL

          results.map do |result|
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
        else
          Assessment.create assessment.to_record
        end
      end
    end

    def check_valid_energy_ratings(assessment)
      if %w[CEPC RdSAP SAP].include? assessment.get(:type_of_assessment)
        current = assessment.get(:current_energy_efficiency_rating)

        unless current.is_a?(Integer) && current.positive?
          raise ArgumentError, "Invalid current energy rating"
        end

        if %w[RdSAP SAP].include? assessment.get(:type_of_assessment)
          potential = assessment.get(:potential_energy_efficiency_rating)

          unless potential.is_a?(Integer) && potential.positive?
            raise ArgumentError, "Invalid potential energy rating"
          end
        end
      end
    end
  end
end
