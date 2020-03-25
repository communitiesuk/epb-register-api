module Boundary
  class MigrateDomesticEpcRequest
    def initialize(assessment_id, data)
      @data = data
      @assessment_id = assessment_id
    end

    def to_domain
      Domain::DomesticEnergyAssessment.new(
        @data[:date_of_assessment],
        @data[:date_registered],
        @data[:dwelling_type],
        @data[:type_of_assessment],
        @data[:total_floor_area],
        @assessment_id,
        @data[:scheme_assessor_id],
        @data[:address_summary],
        @data[:current_energy_efficiency_rating],
        @data[:potential_energy_efficiency_rating],
        @data[:postcode],
        @data[:date_of_expiry],
        @data[:address_line1],
        @data[:address_line2],
        @data[:address_line3],
        @data[:address_line4],
        @data[:town],
        @data[:heat_demand][:current_space_heating_demand],
        @data[:heat_demand][:current_water_heating_demand],
        @data[:heat_demand][:impact_of_loft_insulation],
        @data[:heat_demand][:impact_of_cavity_insulation],
        @data[:heat_demand][:impact_of_solid_wall_insulation],
        @data[:recommended_improvements].map do |i|
          Domain::RecommendedImprovement.new(@assessment_id, i[:sequence])
        end
      )
    end
  end
end
