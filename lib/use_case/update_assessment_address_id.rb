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
      @assessment_gateway = Gateway::AssessmentsGateway.new
    end

    def execute(assessment_id, new_address_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      assessments_ids = [assessment_id]
      linked_assessment_id =
        @assessment_gateway.get_linked_assessment_id(assessment_id)
      assessments_ids << linked_assessment_id unless linked_assessment_id.nil?

      assessments_ids.each do |current_assessment_id|
        check_assessment_exists(current_assessment_id)
        validate_new_address_id(current_assessment_id, new_address_id)
      end

      @assessments_address_id_gateway.update_assessments_address_id_mapping(
        assessments_ids,
        new_address_id,
      )
    end

  private

    def check_assessment_exists(assessment_id)
      assessment =
        @assessments_search_gateway.search_by_assessment_id(
          assessment_id,
          false,
        ).first

      raise AssessmentNotFound unless assessment
    end

    def validate_new_address_id(assessment_id, new_address_id)
      if new_address_id.start_with? "UPRN-"
        linking_to_uprn = new_address_id[5..-1]
        if @address_base_gateway.search_by_uprn(linking_to_uprn).empty?
          raise AddressIdNotFound
        end
      elsif new_address_id.start_with? "RRN-"
        linking_to_rrn = new_address_id[4..-1]
        if @assessments_search_gateway.search_by_assessment_id(linking_to_rrn)
             .empty?
          raise AddressIdNotFound
        end

        rrn_assessment_address_id =
          @assessments_address_id_gateway.fetch(linking_to_rrn)[:address_id]

        # This a new address ID and the new assessment address ID points to itself
        if (new_address_id != rrn_assessment_address_id) &&
            (linking_to_rrn != assessment_id)
          raise AddressIdMismatched,
                "Assessment #{linking_to_rrn} is linked to address ID #{rrn_assessment_address_id}"
        end
      end
    end
  end
end
