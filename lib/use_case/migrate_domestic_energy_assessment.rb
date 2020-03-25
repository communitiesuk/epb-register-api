module UseCase
  class MigrateDomesticEnergyAssessment
    SEQUENCE_ERROR = 'Sequences must contain 0 and be continuous'
    def initialize(domestic_energy_assessments_gateway, assessors_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def check_improvements(improvements)
      sequences = improvements.map(&:sequence)

      raise ArgumentError.new(SEQUENCE_ERROR) unless sequences.include? 0

      unless sequences.sort.each_cons(2).all? { |x, y| y == x + 1 }
        raise ArgumentError.new(SEQUENCE_ERROR)
      end
    end

    def execute(migrate_domestic_energy_assessment_request)
      request_data = migrate_domestic_energy_assessment_request.data
      assessor_id = request_data[:scheme_assessor_id]
      assessor = @assessors_gateway.fetch(assessor_id)

      assessment =
        Domain::DomesticEnergyAssessment.new(
          request_data[:date_of_assessment],
          request_data[:date_registered],
          request_data[:dwelling_type],
          request_data[:type_of_assessment],
          request_data[:total_floor_area],
          migrate_domestic_energy_assessment_request.assessment_id,
          assessor,
          request_data[:address_summary],
          request_data[:current_energy_efficiency_rating],
          request_data[:potential_energy_efficiency_rating],
          request_data[:postcode],
          request_data[:date_of_expiry],
          request_data[:address_line1],
          request_data[:address_line2],
          request_data[:address_line3],
          request_data[:address_line4],
          request_data[:town],
          request_data[:heat_demand][:current_space_heating_demand],
          request_data[:heat_demand][:current_water_heating_demand],
          request_data[:heat_demand][:impact_of_loft_insulation],
          request_data[:heat_demand][:impact_of_cavity_insulation],
          request_data[:heat_demand][:impact_of_solid_wall_insulation],
          request_data[:recommended_improvements].map do |i|
            Domain::RecommendedImprovement.new(
              migrate_domestic_energy_assessment_request.assessment_id,
              i[:sequence]
            )
          end
        )

      check_improvements(assessment.recommended_improvements)

      @domestic_energy_assessments_gateway.insert_or_update(assessment)
      assessment
    end
  end
end
