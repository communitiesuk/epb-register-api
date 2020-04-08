# frozen_string_literal: true

module UseCase
  class MigrateDomesticEnergyAssessment
    class AssessmentRuleException < Exception; end

    def initialize(domestic_energy_assessments_gateway, assessors_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(assessment_id, assessment_data)
      assessor_id = assessment_data[:scheme_assessor_id]
      assessor = @assessors_gateway.fetch(assessor_id)

      assessment =
        Domain::DomesticEnergyAssessment.new(
          assessment_data[:date_of_assessment],
          assessment_data[:date_registered],
          assessment_data[:dwelling_type],
          assessment_data[:type_of_assessment],
          assessment_data[:total_floor_area],
          assessment_id,
          assessor,
          assessment_data[:address_summary],
          assessment_data[:current_energy_efficiency_rating],
          assessment_data[:potential_energy_efficiency_rating],
          assessment_data[:postcode],
          assessment_data[:date_of_expiry],
          assessment_data[:address_line1],
          assessment_data[:address_line2],
          assessment_data[:address_line3],
          assessment_data[:address_line4],
          assessment_data[:town],
          assessment_data[:heat_demand][:current_space_heating_demand],
          assessment_data[:heat_demand][:current_water_heating_demand],
          assessment_data[:heat_demand][:impact_of_loft_insulation],
          assessment_data[:heat_demand][:impact_of_cavity_insulation],
          assessment_data[:heat_demand][:impact_of_solid_wall_insulation],
          assessment_data[:recommended_improvements].map do |i|
            Domain::RecommendedImprovement.new(
              assessment_id,
              i[:sequence],
              i[:improvement_code],
              i[:indicative_cost],
              i[:typical_saving] ? i[:typical_saving].round(2) : 0,
              i[:improvement_category],
              i[:improvement_type],
              i[:energy_performance_rating],
              i[:environmental_impact_rating],
              i[:green_deal_category_code]
            )
          end
        )

      validator = Helper::RdsapValidator::ValidateAll.new
      errors = validator.validate(assessment)

      raise AssessmentRuleException.new(errors.to_json) unless errors.empty?

      @domestic_energy_assessments_gateway.insert_or_update(assessment)
      assessment
    end
  end
end
