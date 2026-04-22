module Domain
  class ScottishAssessmentMetaData
    def initialize(
      meta_data:
    )
      @type_of_assessment = meta_data[:type_of_assessment]
      @opt_out = meta_data[:opt_out]
      @created_at = meta_data[:created_at]
      @cancelled_at = meta_data[:cancelled_at]
      @not_for_issue_at = meta_data[:not_for_issue_at]
      @schema_type = meta_data[:schema_type]
      @property_id = meta_data[:assessment_address_id]
      @date_of_expiry = meta_data[:date_of_expiry]
    end

    def to_hash
      {
        status: get_status,
        optOut: @opt_out,
        createdAt: @created_at,
        cancelledAt: get_cancelled_at,
        typeOfAssessment: @type_of_assessment,
        schemaType: @schema_type,
        propertyId: @property_id,
      }
    end

  private

    def get_status
      if !@cancelled_at.nil? || !@not_for_issue_at.nil?
        "CANCELLED"
      elsif @date_of_expiry < Time.now
        "EXPIRED"
      else
        "ENTERED"
      end
    end

    def get_cancelled_at
      if !@cancelled_at.nil?
        @cancelled_at
      elsif !@not_for_issue_at.nil?
        @not_for_issue_at
      else
        nil
      end
    end
  end
end
