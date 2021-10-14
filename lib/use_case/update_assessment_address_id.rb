# frozen_string_literal: true

module UseCase
  class UpdateAssessmentAddressId
    class AddressIdMismatched < StandardError; end

    class AddressIdNotFound < StandardError; end

    class AssessmentNotFound < StandardError; end

    class InvalidAddressIdFormat < StandardError; end

    def initialize(
      address_base_gateway:,
      assessments_address_id_gateway:,
      assessments_search_gateway:,
      assessments_gateway:,
      event_broadcaster:
    )
      @address_base_gateway = address_base_gateway
      @assessments_address_id_gateway = assessments_address_id_gateway
      @assessments_search_gateway = assessments_search_gateway
      @assessments_gateway = assessments_gateway
      @event_broadcaster = event_broadcaster
    end

    def execute(assessment_id, new_address_id)
      validate_address_id_format(new_address_id)

      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      assessments_ids = [assessment_id]
      linked_assessment_id =
        @assessments_gateway.get_linked_assessment_id(assessment_id)
      assessments_ids << linked_assessment_id unless linked_assessment_id.nil?

      assessments_ids.each do |current_assessment_id|
        check_assessment_exists(current_assessment_id)
      end

      validate_new_address_id(assessments_ids, new_address_id)

      @assessments_address_id_gateway.update_assessments_address_id_mapping(
        assessments_ids,
        new_address_id,
      )

      assessments_ids.each do |id|
        @event_broadcaster.broadcast :assessment_address_id_updated,
                                     assessment_id: id,
                                     new_address_id: new_address_id
      end
    end

  private

    def check_assessment_exists(assessment_id)
      assessment =
        @assessments_search_gateway.search_by_assessment_id(
          assessment_id,
          restrictive: false,
        ).first

      raise AssessmentNotFound unless assessment
    end

    def validate_address_id_format(new_address_id)
      raise InvalidAddressIdFormat, "AddressId has to begin with UPRN- or RRN-" unless new_address_id.start_with?("UPRN-", "RRN-")

      raise InvalidAddressIdFormat, "RRN number is not in the correct format" if new_address_id.start_with?("RRN-") && !Helper::RrnHelper.valid_format?(new_address_id[4..])
    end

    def validate_new_address_id(assessment_ids, new_address_id)
      if new_address_id.start_with? "UPRN-"
        linking_to_uprn = new_address_id[5..]
        unless @address_base_gateway.check_uprn_exists(linking_to_uprn)
          raise AddressIdNotFound
        end
      elsif new_address_id.start_with? "RRN-"
        linking_to_rrn = new_address_id[4..]
        if @assessments_search_gateway.search_by_assessment_id(linking_to_rrn)
                                      .empty?
          raise AddressIdNotFound
        end

        rrn_assessment_address_id =
          @assessments_address_id_gateway.fetch(linking_to_rrn)[:address_id]

        # This a new address ID and the new assessment address ID points to itself
        if new_address_id != rrn_assessment_address_id &&
            !assessment_ids.include?(linking_to_rrn)
          raise AddressIdMismatched,
                "Assessment #{linking_to_rrn} is linked to address ID #{rrn_assessment_address_id}"
        end
      end
    end
  end
end
