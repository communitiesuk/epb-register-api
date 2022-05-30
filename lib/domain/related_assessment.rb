module Domain
  class RelatedAssessment
    def initialize(
      assessment_id:,
      assessment_status:,
      assessment_type:,
      assessment_expiry_date:,
      opt_out:
    )
      @assessment_id = assessment_id
      @assessment_status = assessment_status
      @assessment_type = assessment_type
      @assessment_expiry_date = assessment_expiry_date
      @opt_out = opt_out
    end

    def to_hash
      {
        assessment_id: @assessment_id,
        assessment_status: @assessment_status,
        assessment_type: @assessment_type,
        assessment_expiry_date: @assessment_expiry_date.strftime("%Y-%m-%d"),
        opt_out: @opt_out,
      }
    end
  end
end
