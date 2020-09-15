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

      scheme_assessor_id = data[:assessor_id].nil? ? data[:assessor][:scheme_assessor_id] : data[:assessor_id]

      expiry_date = data[:date_of_expiry] || Date.parse(data[:date_of_assessment]).next_year(10).to_s

      assessor = @assessors_gateway.fetch scheme_assessor_id

      check_assessor_qualification data, assessor unless migrated

      assessment =
        Domain::AssessmentIndexRecord.new(
          assessment_id: data[:assessment_id],
          type_of_assessment: data[:type_of_assessment],
          date_of_assessment: data[:date_of_assessment],
          date_registered: data[:date_of_registration],
          date_of_expiry: expiry_date,
          assessor: assessor,
          current_energy_efficiency_rating: data[:current_energy_efficiency_rating].to_i,
          potential_energy_efficiency_rating:
            data[:potential_energy_efficiency_rating].to_i,
          address_id: data[:address][:address_id] || nil,
          address_line1: data[:address][:address_line1],
          address_line2: data[:address][:address_line2] || "",
          address_line3: data[:address][:address_line3] || "",
          address_line4: data[:address][:address_line4],
          town: data[:address][:town],
          postcode: data[:address][:postcode],
          xml: data[:raw_data],
          migrated: migrated,
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
      active_status = "ACTIVE"

      if data[:type_of_assessment] == "RdSAP" &&
          assessor.domestic_rd_sap_qualification != active_status
        raise InactiveAssessorException
      end

      if data[:type_of_assessment] == "SAP" &&
          assessor.domestic_sap_qualification != active_status
        raise InactiveAssessorException
      end

      if %w[CEPC CEPC-RR].include?(data[:type_of_assessment])
        if data[:building_complexity]
          level = data[:building_complexity][-1]

          if assessor.send(:"non_domestic_nos#{level}_qualification") !=
              active_status
            raise InactiveAssessorException
          end
        end

        if assessor.non_domestic_nos3_qualification != active_status &&
            assessor.non_domestic_nos4_qualification != active_status &&
            assessor.non_domestic_nos5_qualification != active_status
          raise InactiveAssessorException
        end
      end

      if %w[DEC DEC-RR].include?(data[:type_of_assessment]) &&
          assessor.non_domestic_dec_qualification != active_status
        raise InactiveAssessorException
      end

      if data[:type_of_assessment] == "AC-REPORT" &&
          assessor.non_domestic_sp3_qualification != active_status
        raise InactiveAssessorException
      end

      if data[:type_of_assessment] == "AC-CERT" &&
          assessor.non_domestic_cc4_qualification != active_status
        raise InactiveAssessorException
      end
    end
  end
end
