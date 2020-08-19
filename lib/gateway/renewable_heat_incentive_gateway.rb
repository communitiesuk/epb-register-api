module Gateway
  class RenewableHeatIncentiveGateway
    TENURE = {
      "1" => "Owner-occupied",
      "2" => "Rented (social)",
      "3" => "Rented (private)",
      "ND" => "Unknown",
    }.freeze

    class Assessor < ActiveRecord::Base; end

    def fetch(assessment_id)
      sql = <<-SQL
        SELECT
          assessments.assessment_id, scheme_assessor_id, date_of_assessment,
          date_registered, type_of_assessment,
          current_energy_efficiency_rating, potential_energy_efficiency_rating,
          postcode, current_space_heating_demand, current_water_heating_demand,
          impact_of_loft_insulation, tenure, property_age_band, cancelled_at,
          impact_of_cavity_insulation, property_summary, not_for_issue_at,
          string_agg(improvement_type, ', ') AS improvement_type
        FROM assessments
        LEFT JOIN domestic_epc_energy_improvements deei
          ON assessments.assessment_id = deei.assessment_id
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

      result.reduce
    end

  private

    def record_to_rhi_domain(row)

      assessment_summary = UseCase::AssessmentSummary::Fetch.new.execute(row["assessment_id"])


      Domain::RenewableHeatIncentive.new(
        epc_rrn: row["assessment_id"],
        is_cancelled: row["cancelled_at"] || row["not_for_issue_at"],
        assessor_name: fetch_assessor_name(row["scheme_assessor_id"]),
        report_type: row["type_of_assessment"],
        inspection_date: row["date_registered"],
        lodgement_date: row["date_of_assessment"],
        dwelling_type: assessment_summary[:dwelling_type],
        postcode: row["postcode"],
        property_age_band: row["property_age_band"],
        tenure: TENURE[row["tenure"]],
        total_floor_area: assessment_summary[:total_floor_area],
        cavity_wall_insulation: insulation?("B", row),
        loft_insulation: insulation?("A", row),
        space_heating: row["current_space_heating_demand"],
        water_heating: row["current_water_heating_demand"],
        secondary_heating:
          fetch_property_description(
            row["property_summary"],
            "secondary_heating",
          ),
        energy_efficiency: {
          current_rating: row["current_energy_efficiency_rating"],
          current_band:
            get_energy_rating_band(row["current_energy_efficiency_rating"]),
          potential_rating: row["potential_energy_efficiency_rating"],
          potential_band:
            get_energy_rating_band(row["potential_energy_efficiency_rating"]),
        },
      )
    end

    def insulation?(type, row)
      unless row["type_of_assessment"] == "SAP" || row["improvement_type"].nil?
        return row["improvement_type"].include?(type)
      end

      false
    end

    def fetch_assessor_name(scheme_assessor_id)
      assessor = Assessor.find_by scheme_assessor_id: scheme_assessor_id

      [
        assessor["first_name"],
        assessor["middle_names"],
        assessor["last_name"],
      ].compact.join(" ")
    end

    def fetch_property_description(property, name)
      summary = JSON.parse property

      summary.each do |field|
        return field["description"] if field["name"] == name
      end

      nil
    end

    def get_energy_rating_band(number)
      case number
      when 1..20
        "g"
      when 21..38
        "f"
      when 39..54
        "e"
      when 55..68
        "d"
      when 69..80
        "c"
      when 81..91
        "b"
      when 92..1_000
        "a"
      end
    end
  end
end
