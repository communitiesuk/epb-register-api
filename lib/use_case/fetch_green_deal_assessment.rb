module UseCase
  class FetchGreenDealAssessment
    class AssessmentIdIsBadlyFormatted < StandardError; end
    VALID_RRN = "^(\\d{4}-){4}\\d{4}$".freeze

    def execute(assessment_id)
      raise AssessmentIdIsBadlyFormatted unless Regexp.new(VALID_RRN).match(assessment_id)
    end
  end
end
