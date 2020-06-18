module Gateway
  class RenewableHeatIncentiveGateway
    class Assessment < ActiveRecord::Base; end
    class Assessor < ActiveRecord::Base; end

    def fetch(assessment_id)
      sql =
        "SELECT
          scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
          type_of_assessment, total_floor_area, current_energy_efficiency_rating,
          potential_energy_efficiency_rating, postcode, current_space_heating_demand,
          current_water_heating_demand, impact_of_loft_insulation,
          impact_of_cavity_insulation, impact_of_solid_wall_insulation
          FROM assessments
        WHERE assessment_id = $1 AND type_of_assessment IN('RdSAP', 'SAP')"

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds

      result = results.map { |row| record_to_rhi_domain row }

      result.empty? ? result.reduce : result
    end

  private

    def record_to_rhi_domain(row)
      Domain::RenewableHeatIncentive.new(
        epc_rrn: row["assessment_id"],
        assessor_name: nil,
        report_type: row["type_of_assessment"],
        inspection_date: row["date_registered"],
        lodgement_date: row["date_of_assessment"],
        dwelling_type: row["dwelling_type"],
        postcode: row["postcode"],
        property_age_band: row["property_age_band"],
        tenure: row["tenure"],
        total_floor_area: row["total_floor_area"],
        cavity_wall_insulation: nil,
        loft_insulation: nil,
        space_heating: row["current_space_heating_demand"],
        water_heating: row["current_water_heating_demand"],
        secondary_heating: nil,
        energy_efficiency: {
          current_rating: row["current_energy_efficiency_rating"],
          current_band: row["current_band"],
          potential_rating: row["potential_energy_efficiency_rating"],
          potential_band: row["potential_band"],
        },
      )
    end
  end
end
