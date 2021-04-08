# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    class InactiveAssessorException < StandardError
    end
    class AssessmentIdMismatchException < StandardError
    end
    class DuplicateAssessmentIdException < StandardError
    end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
      @assessments_search_gateway = Gateway::AssessmentsSearchGateway.new
      @address_base_search_gateway = Gateway::AddressBaseSearchGateway.new
      @assessors_gateway = Gateway::AssessorsGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
      @assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
    end

    def execute(data, migrated, schema_name)
      assessment_id = data[:assessment_id]

      unless migrated
        if @assessments_search_gateway.search_by_assessment_id(
          assessment_id,
          false,
        ).first
          raise DuplicateAssessmentIdException
        end
      end

      scheme_assessor_id =
        if data[:assessor_id].nil?
          data[:assessor][:scheme_assessor_id]
        else
          data[:assessor_id]
        end

      assessor = @assessors_gateway.fetch scheme_assessor_id

      check_assessor_qualification data, assessor unless migrated

      assessment =
        Domain::AssessmentIndexRecord.new(
          assessment_id: data[:assessment_id],
          type_of_assessment: data[:type_of_assessment],
          date_of_assessment: data[:date_of_assessment],
          date_registered: data[:date_of_registration],
          date_of_expiry: data[:date_of_expiry],
          assessor: assessor,
          current_energy_efficiency_rating:
            data[:current_energy_efficiency_rating].to_i,
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
          related_rrn: find_related_rrn(data),
        )

      @assessments_gateway.insert_or_update assessment

      save_new_address_id assessment

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

      if %w[AC-CERT AC-REPORT].include?(data[:type_of_assessment]) &&
          assessor.non_domestic_sp3_qualification != active_status &&
          assessor.non_domestic_cc4_qualification != active_status
        raise InactiveAssessorException
      end
    end

    def find_related_rrn(wrapper_hash)
      related_rrn = nil

      # related-rrn: AC-CERT AC-REPORT CEPC DEC-RR
      related_rrn = wrapper_hash[:related_rrn] unless wrapper_hash[:related_rrn]
        .nil?

      # related_certificate: CEPC-RR
      related_rrn = wrapper_hash[:related_certificate] unless wrapper_hash[
        :related_certificate
      ].nil?

      # administrative_information->related_rrn: DEC
      if related_rrn.nil? &&
          !wrapper_hash.dig(:administrative_information, :related_rrn).nil?
        related_rrn = wrapper_hash[:administrative_information][:related_rrn]
      end
      related_rrn
    end

    def save_new_address_id(assessment)
      new_address_id = assessment.address_id

      if new_address_id.nil?
        new_address_id = default_address_id(assessment)
      elsif new_address_id.start_with?("UPRN-")
        # TODO: Maybe in the future, prevent assessors from lodging non existing UPRNs
        uprn = new_address_id[5..-1].to_i.to_s
        uprn_search_result = @address_base_search_gateway.search_by_uprn(uprn)
        new_address_id = default_address_id(assessment) if uprn_search_result.empty?
      end

      @assessments_address_id_gateway.send_to_db(
        {
          assessment_id: assessment.assessment_id,
          address_id: new_address_id,
          source: "lodgement",
        },
      )
    end

    def default_address_id(assessment)
      default_address_id = "RRN-" + assessment.assessment_id
      if !assessment.related_rrn.nil? &&
          (assessment.type_of_assessment.include?("-RR") || assessment.type_of_assessment.include?("-REPORT"))
        default_address_id = "RRN-" + assessment.related_rrn
      end
      default_address_id
    end
  end
end
