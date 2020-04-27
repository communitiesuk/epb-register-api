# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    class InactiveAssessorException < StandardError; end
    class AssessmentIdMismatch < StandardError; end
    class DuplicateAssessmentIdException < StandardError; end
    class AssessmentRuleException < StandardError; end

    def initialize(domestic_energy_assessments_gateway, assessors_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(lodgement, assessment_id)
      body = lodgement.fetch_raw_data

      data = lodgement.fetch_data

      raise AssessmentIdMismatch unless assessment_id == data[:assessment_id]

      if @domestic_energy_assessments_gateway.fetch assessment_id
        raise DuplicateAssessmentIdException
      end

      scheme_assessor_id = lodgement.scheme_assessor_id

      address_summary =
        [
          data[:address_line_one],
          data[:address_line_two],
          data[:address_line_three],
          data[:town],
          data[:postcode]
        ].compact
          .join(', ')

      expiry_date = Date.parse(data[:inspection_date]).next_year(10).to_s

      assessor = @assessors_gateway.fetch scheme_assessor_id

      unless assessor.domestic_rd_sap_qualification == 'ACTIVE'
        raise InactiveAssessorException
      end

      assessment =
        Domain::DomesticEnergyAssessment.new(
          data[:inspection_date],
          data[:registration_date],
          data[:dwelling_type],
          'RdSAP',
          data[:total_floor_area],
          data[:assessment_id],
          assessor,
          address_summary,
          data[:current_energy_rating].to_i,
          data[:potential_energy_rating].to_i,
          data[:postcode],
          expiry_date,
          data[:address_line_one],
          data[:address_line_two] || '',
          data[:address_line_three] || '',
          '',
          data[:town],
          data[:space_heating],
          data[:water_heating],
          data[:impact_of_loft_insulation],
          data[:impact_of_cavity_insulation],
          data[:impact_of_solid_wall_insulation],
          create_list_of_suggested_improvements(body)
        )

      validator = Helper::RdsapValidator::ValidateAll.new
      errors = validator.validate(assessment)

      raise AssessmentRuleException, errors.to_json unless errors.empty?

      @domestic_energy_assessments_gateway.insert_or_update(assessment)

      assessment
    end

    private

    def create_list_of_suggested_improvements(body)
      suggested_improvements =
        body.dig(
          :RdSAP_Report,
          :Energy_Assessment,
          :Suggested_Improvements,
          :Improvement
        )

      if suggested_improvements.nil?
        []
      else
        unless suggested_improvements.is_a?(Array)
          suggested_improvements = [suggested_improvements]
        end
        suggested_improvements.map do |i|
          Domain::RecommendedImprovement.new(
            fetch(body, :RRN),
            fetch(i, :Sequence).to_i,
            fetch(i, :Improvement_Number),
            fetch(i, :Indicative_Cost),
            fetch(i, :Typical_Saving),
            fetch(i, :Improvement_Category),
            fetch(i, :Improvement_Type),
            fetch(i, :Energy_Performance_Rating),
            fetch(i, :Environmental_Impact_Rating),
            fetch(i, :Green_Deal_Category)
          )
        end
      end
    end

    def fetch(hash, key)
      return hash[key] if hash.fetch(key, false)

      hash.each_key do |hash_key|
        result = fetch(hash[hash_key], key) if hash[hash_key].is_a? Hash
        return result if result
      end

      nil
    end
  end
end
