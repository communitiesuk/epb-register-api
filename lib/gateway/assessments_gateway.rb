# frozen_string_literal: true

module Gateway
  class AssessmentsGateway
    class Assessment < ActiveRecord::Base; end

    class DomesticEpcEnergyImprovement < ActiveRecord::Base; end

    class InvalidAssessmentType < StandardError; end

    def row_to_energy_improvement(row)
      Domain::RecommendedImprovement.new(
        assessment_id: row[:assessment_id],
        sequence: row[:sequence],
        improvement_code: row[:improvement_code],
        indicative_cost: row[:indicative_cost],
        typical_saving: row[:typical_saving],
        improvement_category: row[:improvement_category],
        improvement_type: row[:improvement_type],
        improvement_title: row[:improvement_title],
        improvement_description: row[:improvement_description],
        energy_performance_rating_improvement:
          row[:energy_performance_rating_improvement],
        environmental_impact_rating_improvement:
          row[:environmental_impact_rating_improvement],
        green_deal_category_code: row[:green_deal_category_code],
      )
    end

    def insert_or_update(assessment)
      check_valid_energy_ratings assessment
      send_to_db assessment
    end

    def update_field(assessment_id, field, value)
      sql =
        "UPDATE assessments SET " +
        ActiveRecord::Base.connection.quote_column_name(field) + " = '" +
        ActiveRecord::Base.sanitize_sql(value) + "' WHERE assessment_id = '" +
        ActiveRecord::Base.sanitize_sql(assessment_id) + "'"

      Assessment.connection.execute(sql)
    end

  private

    def send_to_db(assessment)
      ActiveRecord::Base.transaction do
        existing_assessment =
          Assessment.find_by assessment_id: assessment.get(:assessment_id)

        if existing_assessment
          existing_assessment.update assessment.to_record

          binds = [
            ActiveRecord::Relation::QueryAttribute.new(
              "id",
              assessment.get(:assessment_id),
              ActiveRecord::Type::String.new,
            ),
          ]

          ActiveRecord::Base.connection.exec_query(<<~SQL, "SQL", binds)
            DELETE FROM domestic_epc_energy_improvements WHERE assessment_id = $1
          SQL
        else
          Assessment.create assessment.to_record
        end

        assessment.get(:recommended_improvements)&.map(&:to_record)
          &.each do |improvement|
          DomesticEpcEnergyImprovement.create improvement
        end
      end
    end

    def row_to_domain(row)
      row.symbolize_keys!
      row[:property_summary] = JSON.parse(row[:property_summary])
      Domain::Assessment.new(row)
    end

    def check_valid_energy_ratings(assessment)
      if %w[CEPC RdSAP SAP].include? assessment.get(:type_of_assessment)
        current = assessment.get(:current_energy_efficiency_rating)

        unless current.is_a?(Integer) && current.positive?
          raise ArgumentError, "Invalid current energy rating"
        end

        potential = assessment.get(:potential_energy_efficiency_rating)

        unless potential.is_a?(Integer) && potential.positive?
          raise ArgumentError, "Invalid potential energy rating"
        end
      end
    end
  end
end
