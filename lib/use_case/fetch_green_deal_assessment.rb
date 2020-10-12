module UseCase
  class FetchGreenDealAssessment
    class AssessmentIdIsBadlyFormatted < StandardError; end
    class UnauthorisedToFetchThisAssessment < StandardError; end
    class NotFoundException < StandardError; end

    VALID_RRN = "^(\\d{4}-){4}\\d{4}$".freeze

    def initialize
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(assessment_id)
      unless Regexp.new(VALID_RRN).match(assessment_id)
        raise AssessmentIdIsBadlyFormatted
      end

      unless @assessments_xml_gateway.fetch(assessment_id)
        assessment_xml = raise NotFoundException
      end
    end
  end
end
