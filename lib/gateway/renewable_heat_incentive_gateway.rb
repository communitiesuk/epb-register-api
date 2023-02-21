module Gateway
  class RenewableHeatIncentiveGateway
    TENURE = {
      "1" => "Owner-occupied",
      "2" => "Rented (social)",
      "3" => "Rented (private)",
      "ND" => "Unknown",
    }.freeze

    class Assessor < ActiveRecord::Base
    end

    def fetch(assessment_id)
      sql = <<-SQL
        SELECT
          assessments.assessment_id, scheme_assessor_id,
           type_of_assessment, cancelled_at, not_for_issue_at
        FROM assessments
        WHERE assessments.assessment_id = $1
          AND type_of_assessment IN('RdSAP', 'SAP')
        GROUP BY 1
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds

      result = results.map { |row| record_to_rhi_domain row }

      result.first
    end

  private

    def record_to_rhi_domain(row)
      assessment_summary =
        UseCase::AssessmentSummary::Fetch.new.execute(row["assessment_id"])

      Domain::RenewableHeatIncentive.new(
        epc_rrn: assessment_summary[:assessment_id],
        is_cancelled: row["cancelled_at"] || row["not_for_issue_at"],
        assessor_name:
          fetch_assessor_name(
            assessment_summary[:assessor][:scheme_assessor_id],
          ),
        report_type: assessment_summary[:type_of_assessment],
        inspection_date: Date.parse(assessment_summary[:date_of_assessment]),
        lodgement_date: Date.parse(assessment_summary[:date_of_registration]),
        dwelling_type: assessment_summary[:dwelling_type],
        postcode: assessment_summary[:address][:postcode],
        property_age_band: assessment_summary[:property_age_band],
        tenure: TENURE[assessment_summary[:tenure]],
        total_floor_area: assessment_summary[:total_floor_area],
        cavity_wall_insulation: insulation?("B", assessment_summary),
        loft_insulation: insulation?("A", assessment_summary),
        space_heating:
          assessment_summary[:heat_demand][:current_space_heating_demand],
        water_heating:
          assessment_summary[:heat_demand][:current_water_heating_demand],
        secondary_heating:
          fetch_property_description(
            assessment_summary[:property_summary],
            "secondary_heating",
          ),
        energy_efficiency: {
          current_rating: assessment_summary[:current_energy_efficiency_rating],
          current_band: assessment_summary[:current_energy_efficiency_band],
          potential_rating:
            assessment_summary[:potential_energy_efficiency_rating],
          potential_band: assessment_summary[:potential_energy_efficiency_band],
        },
      )
    end

    def insulation?(type, summary)
      unless summary[:type_of_assessment] != "RdSAP" ||
          summary[:type_of_assessment].nil?
        return(
          !summary[:recommended_improvements].select { |i|
            i[:improvement_type] == type
          }.empty?
        )
      end
      false
    end

    def fetch_assessor_name(scheme_assessor_id)
      assessor = Assessor.find_by(scheme_assessor_id:)

      [
        assessor["first_name"],
        assessor["middle_names"],
        assessor["last_name"],
      ].compact.join(" ")
    end

    def fetch_property_description(summary, name)
      summary.each do |feature|
        return feature[:description] if feature[:name] == name
      end

      nil
    end
  end
end
