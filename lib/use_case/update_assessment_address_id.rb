# frozen_string_literal: true

module UseCase
  class UpdateAssessmentAddressId
    class AddressIdMismatched < StandardError
    end
    class AddressIdNotFound < StandardError
    end
    class AssessmentNotFound < StandardError
    end

    def initialize
      @address_base_gateway = Gateway::AddressBaseSearchGateway.new
      @assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
      @assessments_search_gateway = Gateway::AssessmentsSearchGateway.new
    end

    def execute(assessment_id, new_address_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)
      assessment =
        @assessments_search_gateway.search_by_assessment_id(
          assessment_id,
          false,
        ).first

      raise AssessmentNotFound unless assessment

      if new_address_id.start_with? "UPRN-"
        linking_to_uprn = new_address_id[5..-1]
        raise AddressIdNotFound if @address_base_gateway.search_by_uprn(linking_to_uprn).empty?
      elsif new_address_id.start_with? "RRN-"
        linking_to_rrn = new_address_id[4..-1]
        raise AddressIdNotFound if @assessments_search_gateway.search_by_assessment_id(linking_to_rrn).empty?
        rrn_assessment_address_id = @assessments_address_id_gateway.fetch(linking_to_rrn)[:address_id]
        raise AddressIdMismatched.new("Assessment #{linking_to_rrn} is linked to address ID #{rrn_assessment_address_id}") if new_address_id != rrn_assessment_address_id
      end

      # TODO: Get the linked assessment ID here if there is one and update the address ID for that too
      @assessments_address_id_gateway.update_assessment_address_id_mapping(assessment_id, new_address_id)

    end
  end
end
