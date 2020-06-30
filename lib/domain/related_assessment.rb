module Domain
  class RelatedAssessment
    def initialize(
      assessment_id:,
      assessment_status:,
      assessment_type:,
      assessment_expiry_date:
    )
      @assessment_id = assessment_id
      @assessment_status = assessment_status
      @assessment_type = assessment_type
      @assessment_expiry_date = assessment_expiry_date
    end

    def to_hash
      {
        assessment_id: @assessment_id,
        assessment_status: @assessment_status,
        assessment_type: @assessment_type,
        assessment_expiry_date: @assessment_expiry_date.strftime("%Y-%m-%d"),
      }
    end
  end
end
