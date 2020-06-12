# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    class InactiveAssessorException < StandardError; end
    class AssessmentIdMismatchException < StandardError; end
    class DuplicateAssessmentIdException < StandardError; end
    class AssessmentRuleException < StandardError; end

    TYPE2LODGEMENT = {
      "CEPC": Domain::CepcAssessment,
      "SAP": Domain::SapAssessment,
      "RdSAP": Domain::RdsapAssessment,
      "DEC-AR": Domain::DecArAssessment,
      "DEC": Domain::DecAssessment,
      "CEPC-RR": Domain::CepcRrAssessment,
      "ACIC": Domain::AcicAssessment,
      "ACIR": Domain::AcirAssessment,
    }.freeze

    def initialize(
      assessments_gateway, assessors_gateway, assessments_xml_gateway
    )
      @assessments_gateway = assessments_gateway
      @assessors_gateway = assessors_gateway
      @assessments_xml_gateway = assessments_xml_gateway
    end

    def execute(data)
      assessment_id = data[:assessment_id]
      assessment_type = data[:assessment_type]

      if @assessments_gateway.fetch assessment_id
        raise DuplicateAssessmentIdException
      end

      scheme_assessor_id = data[:assessor_id]

      expiry_date = Date.parse(data[:inspection_date]).next_year(10).to_s

      assessor = @assessors_gateway.fetch scheme_assessor_id

      if assessment_type == "RdSAP" &&
          assessor.domestic_rd_sap_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      if assessment_type == "SAP" &&
          assessor.domestic_sap_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      if %w[CEPC CEPC-RR].include?(assessment_type)
        if data[:building_complexity]
          level = data[:building_complexity][-1]

          if assessor.send(:"non_domestic_nos#{level}_qualification") ==
              "INACTIVE"
            raise InactiveAssessorException
          end
        end

        if assessor.non_domestic_nos3_qualification == "INACTIVE" &&
            assessor.non_domestic_nos4_qualification == "INACTIVE" &&
            assessor.non_domestic_nos5_qualification == "INACTIVE"
          raise InactiveAssessorException
        end
      end

      if %w[DEC DEC-AR].include?(assessment_type) &&
          assessor.non_domestic_dec_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      if assessment_type == "ACIR" &&
          assessor.non_domestic_sp3_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      if assessment_type == "ACIC" &&
          assessor.non_domestic_cc4_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      data[:improvements] =
        data[:improvements].map do |improvement|
          improvement[:assessment_id] = assessment_id
          Domain::RecommendedImprovement.new(improvement)
        end

      assessment =
        TYPE2LODGEMENT[assessment_type.to_sym].new(
          date_of_assessment: data[:inspection_date],
          date_registered: data[:registration_date],
          dwelling_type: data[:dwelling_type],
          type_of_assessment: assessment_type,
          total_floor_area: data[:total_floor_area],
          assessment_id: data[:assessment_id],
          assessor: assessor,
          current_energy_efficiency_rating: data[:current_energy_rating].to_i,
          potential_energy_efficiency_rating:
            data[:potential_energy_rating].to_i,
          current_carbon_emission: data[:current_carbon_emission],
          potential_carbon_emission: data[:potential_carbon_emission],
          postcode: data[:postcode],
          date_of_expiry: data[:date_of_expiry] || expiry_date,
          address_id: data[:address_id] || nil,
          address_line1: data[:address_line_one],
          address_line2: data[:address_line_two] || "",
          address_line3: data[:address_line_three] || "",
          address_line4: "",
          town: data[:town],
          current_space_heating_demand:
            data[:space_heating] || data[:new_space_heating],
          current_water_heating_demand:
            data[:water_heating] || data[:new_water_heating],
          impact_of_loft_insulation: data[:impact_of_loft_insulation],
          impact_of_cavity_insulation: data[:impact_of_cavity_insulation],
          impact_of_solid_wall_insulation:
            data[:impact_of_solid_wall_insulation],
          recommended_improvements: data[:improvements],
          related_party_disclosure_number:
            data[:related_party_disclosure_number],
          related_party_disclosure_text: data[:related_party_disclosure_text],
          property_summary: data[:property_summary],
          xml: data[:raw_data],
        )

      validator = Helper::RdsapValidator::ValidateAll.new
      errors = validator.validate assessment

      raise AssessmentRuleException, errors.to_json unless errors.empty?

      @assessments_gateway.insert_or_update assessment

      @assessments_xml_gateway.send_to_db(
        { assessment_id: data[:assessment_id], xml: data[:raw_data] },
      )

      assessment
    end
  end
end
