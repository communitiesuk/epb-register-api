module UseCase
  class FetchGreenDealAssessment
    class AssessmentIdIsBadlyFormatted < StandardError; end
    VALID_RRN = "^(\\d{4}-){4}\\d{4}$".freeze

    def execute(assessment_id)
      unless Regexp.new(VALID_RRN).match(assessment_id)
        raise AssessmentIdIsBadlyFormatted
      end
    end
  end
end
