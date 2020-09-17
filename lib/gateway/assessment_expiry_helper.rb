module Gateway
  class AssessmentExpiryHelper

    def initialize(cancelled_at, not_for_issue_at, date_of_expiry)
      @cancelled_at = cancelled_at
      @not_for_issue_at = not_for_issue_at
      @date_of_expiry = date_of_expiry
    end

    def assessment_status
      if !@cancelled_at.nil?
        "CANCELLED"
      elsif !@not_for_issue_at.nil?
        "NOT_FOR_ISSUE"
      elsif @date_of_expiry < Time.now
        "EXPIRED"
      else
        "ENTERED"
      end
    end

  end
end

