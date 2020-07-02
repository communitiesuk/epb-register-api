# frozen_string_literal: true

module UseCase
  class MigrateAssessment
    class AssessmentRuleException < StandardError; end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
      @assessors_gateway = Gateway::AssessorsGateway.new
    end

    def execute(assessment_id, assessment_data)
      assessor_id = assessment_data[:scheme_assessor_id]
      assessor = @assessors_gateway.fetch(assessor_id)

      assessment =
        Domain::Assessment.new(
          date_of_assessment: assessment_data[:date_of_assessment],
          date_registered: assessment_data[:date_registered],
          dwelling_type: assessment_data[:dwelling_type],
          type_of_assessment: assessment_data[:type_of_assessment],
          total_floor_area: assessment_data[:total_floor_area],
          assessment_id: assessment_id,
          assessor: assessor,
          current_energy_efficiency_rating:
            assessment_data[:current_energy_efficiency_rating],
          potential_energy_efficiency_rating:
            assessment_data[:potential_energy_efficiency_rating],
          current_carbon_emission: assessment_data[:current_carbon_emission],
          potential_carbon_emission:
            assessment_data[:potential_carbon_emission],
          opt_out: assessment_data[:opt_out],
          postcode: assessment_data[:postcode],
          date_of_expiry: assessment_data[:date_of_expiry],
          address_line1: assessment_data[:address_line1],
          address_line2: assessment_data[:address_line2],
          address_line3: assessment_data[:address_line3],
          address_line4: assessment_data[:address_line4],
          town: assessment_data[:town],
          current_space_heating_demand:
            assessment_data[:heat_demand][:current_space_heating_demand],
          current_water_heating_demand:
            assessment_data[:heat_demand][:current_water_heating_demand],
          impact_of_loft_insulation:
            assessment_data[:heat_demand][:impact_of_loft_insulation],
          impact_of_cavity_insulation:
            assessment_data[:heat_demand][:impact_of_cavity_insulation],
          impact_of_solid_wall_insulation:
            assessment_data[:heat_demand][:impact_of_solid_wall_insulation],
          recommended_improvements:
            assessment_data[:recommended_improvements].map do |i|
              Domain::RecommendedImprovement.new(
                assessment_id: assessment_id,
                sequence: i[:sequence],
                improvement_code: i[:improvement_code],
                indicative_cost: i[:indicative_cost],
                typical_saving:
                  i[:typical_saving] ? i[:typical_saving].round(2) : 0,
                improvement_category: i[:improvement_category],
                improvement_type: i[:improvement_type],
                improvement_title: i[:improvement_title],
                improvement_description: i[:improvement_description],
                energy_performance_rating_improvement:
                  i[:energy_performance_rating_improvement],
                environmental_impact_rating_improvement:
                  i[:environmental_impact_rating_improvement],
                green_deal_category_code: i[:green_deal_category_code],
              )
            end,
          property_summary: assessment_data[:property_summary],
          related_party_disclosure_number:
            assessment_data[:related_party_disclosure_number],
          related_party_disclosure_text:
            assessment_data[:related_party_disclosure_text],
        )

      if assessment_data[:type_of_assessment] == "RdSAP"
        validator = Helper::RdsapValidator::ValidateAll.new
        errors = validator.validate(assessment)

        raise AssessmentRuleException, errors.to_json unless errors.empty?
      end

      @assessments_gateway.insert_or_update(assessment)

      assessment
    end
  end
end
