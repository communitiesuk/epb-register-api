module Gateway
  class RenewableHeatIncentiveGateway
    class Assessment < ActiveRecord::Base; end
    class Assessor < ActiveRecord::Base; end

    def fetch(assessment_id)
      search_by_assessment_id(assessment_id)
    end

  private

    def search_by_assessment_id(assessment_id)
      sql =
        "SELECT
          scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
          type_of_assessment, total_floor_area, current_energy_efficiency_rating,
          potential_energy_efficiency_rating, postcode, current_space_heating_demand,
          current_water_heating_demand, impact_of_loft_insulation,
          impact_of_cavity_insulation, impact_of_solid_wall_insulation
          FROM assessments
        WHERE assessment_id = '#{
          ActiveRecord::Base.sanitize_sql(assessment_id)
        }' AND type_of_assessment IN('RdSAP', 'SAP')"

      response = Assessment.connection.execute(sql)
      row = response.entries.first.symbolize_keys!
      
        result = Domain::RenewableHeatIncentive.new(
          epcRrn: row[:assessment_id],
          assessorName: row[:scheme_assessor_id],
          reportType: row[:type_of_assessment],
          inspectionDate: row[:date_of_assessment],
          lodgementDate: row[:date_registered],
          dwellingType: row[:dwelling_type],
          postcode: row[:postcode],
          propertyAgeBand: "D",
          tenure: "Owner-occupied",
          totalFloorArea: row[:total_floor_area],
          cavityWallInsulation: false,
          loftInsulation: true,
          spaceHeating: row[:current_space_heating_demand],
          waterHeating: row[:current_water_heating_demand],
          secondaryHeating: "Electric bar heater",
          currentRating: row[:current_energy_efficiency_rating],
          currentBand: row[:current_energy_efficiency_rating],
          potentialRating: row[:potential_energy_efficiency_rating],
          potentialBand: row[:potential_energy_efficiency_rating],
        ).to_hash

    end
  end
end
