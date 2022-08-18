module UseCase
  ##
  # Use case to get the canonical address ID to use for an assessment.
  class GetCanonicalAddressId
    def initialize(
      address_base_search_gateway: nil,
      assessments_address_id_gateway: nil,
      assessments_search_gateway: nil
    )
      @address_base_search_gateway = address_base_search_gateway || Gateway::AddressBaseSearchGateway.new
      @assessments_address_id_gateway = assessments_address_id_gateway || Gateway::AssessmentsAddressIdGateway.new
      @assessments_search_gateway = assessments_search_gateway || Gateway::AssessmentsSearchGateway.new
    end

    def execute(rrn:, address_id:, type_of_assessment: nil, related_rrn: nil)
      if address_id.nil?
        return default_address_id(rrn:, related_rrn:, type_of_assessment:)
      elsif address_id.start_with?("UPRN-")
        # TODO: Maybe in the future, prevent assessors from lodging non existing UPRNs
        uprn = address_id[5..]
        return address_id if address_base_has_uprn?(uprn)
      elsif address_id.start_with?("RRN-")
        related_assessment_id = address_id[4..]
        begin
          related_assessment =
            @assessments_address_id_gateway.fetch(related_assessment_id)
        rescue ActiveRecord::RecordNotFound
          related_assessment = nil
        end

        return related_assessment[:address_id] if related_assessment
      end

      default_address_id(rrn:, related_rrn:, type_of_assessment:)
    end

  private

    def default_address_id(rrn:, related_rrn:, type_of_assessment:)
      default_address_id = "RRN-#{rrn}"
      if !related_rrn.nil? && is_related_report?(type_of_assessment:)
        default_address_id = "RRN-#{related_rrn}"
      end
      default_address_id
    end

    def is_related_report?(type_of_assessment:)
      return false if type_of_assessment.nil?

      (
        type_of_assessment.include?("-RR") ||
          type_of_assessment.include?("-REPORT")
      )
    end

    def address_base_has_uprn?(uprn)
      @address_base_search_gateway.check_uprn_exists(uprn)
    end
  end
end
