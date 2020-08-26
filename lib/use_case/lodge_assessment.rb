# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    class InactiveAssessorException < StandardError; end
    class AssessmentIdMismatchException < StandardError; end
    class DuplicateAssessmentIdException < StandardError; end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
      @assessments_search_gateway = Gateway::AssessmentsSearchGateway.new
      @assessors_gateway = Gateway::AssessorsGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(data, migrated, schema_name)
      assessment_id = data[:assessment_id]

      unless migrated
        if @assessments_search_gateway.search_by_assessment_id(assessment_id)
             .first
          raise DuplicateAssessmentIdException
        end
      end

      scheme_assessor_id = data[:assessor_id]

      expiry_date = Date.parse(data[:inspection_date]).next_year(10).to_s

      assessor = @assessors_gateway.fetch scheme_assessor_id

      check_assessor_qualification data, assessor unless migrated

      if data[:property_details].is_a? Array
        data[:property_details].each do |building|
          next unless building[:building_part_number] == 1

          data[:property_age_band] =
            if building[:construction_age_band] && building[:construction_year]
              building[:construction_year]
            else
              building[:construction_age_band] || building[:construction_year]
            end
        end
      end

      assessment =
        Domain::AssessmentIndexRecord.new(
          migrated: migrated,
          date_of_assessment: data[:inspection_date],
          date_registered: data[:registration_date],
          type_of_assessment: data[:assessment_type],
          assessment_id: data[:assessment_id],
          assessor: assessor,
          current_energy_efficiency_rating: data[:current_energy_rating].to_i,
          potential_energy_efficiency_rating:
            data[:potential_energy_rating].to_i,
          postcode: data[:postcode],
          date_of_expiry: data[:date_of_expiry] || expiry_date,
          address_id: data[:address_id] || nil,
          address_line1: data[:address_line_one],
          address_line2: data[:address_line_two] || "",
          address_line3: data[:address_line_three] || "",
          address_line4: "",
          town: data[:town],
          xml: data[:raw_data],
        )

      @assessments_gateway.insert_or_update assessment

      @assessments_xml_gateway.send_to_db(
        {
          assessment_id: data[:assessment_id],
          xml: data[:raw_data],
          schema_type: schema_name,
        },
      )

      assessment
    end

  private

    def check_assessor_qualification(data, assessor)
      if data[:assessment_type] == "RdSAP" &&
          assessor.domestic_rd_sap_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      if data[:assessment_type] == "SAP" &&
          assessor.domestic_sap_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      if %w[CEPC CEPC-RR].include?(data[:assessment_type])
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

      if %w[DEC DEC-RR].include?(data[:assessment_type]) &&
          assessor.non_domestic_dec_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      if data[:assessment_type] == "AC-REPORT" &&
          assessor.non_domestic_sp3_qualification == "INACTIVE"
        raise InactiveAssessorException
      end

      if data[:assessment_type] == "AC-CERT" &&
          assessor.non_domestic_cc4_qualification == "INACTIVE"
        raise InactiveAssessorException
      end
    end
  end
end
