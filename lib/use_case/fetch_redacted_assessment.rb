module UseCase
  class FetchRedactedAssessment
    class NotFoundException < StandardError
    end

    class AssessmentGone < StandardError
    end

    class SchemeIdsDoNotMatch < StandardError
    end

    class NotAnRdsap < StandardError
    end

    REDACTED_TAGS = %w[
      Identification
      Configuration
      Calculation-Software-Name
      Calculation-Software-Version
      Inspection-Date
      Completion-Date
      Registration-Date
      Status
      Restricted-Access
      Transaction-Type
      Seller-Commission-Report
      Energy-Assessor
      Address
      Related-Party-Disclosure
      Insurance-Details
    ].freeze

    def initialize
      @assessments_gateway = Gateway::AssessmentsSearchGateway.new
      @assessors_gateway = Gateway::AssessorsGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(assessment_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)
      assessments =
        @assessments_gateway.search_by_assessment_id assessment_id, false

      assessment = assessments.first

      raise NotFoundException unless assessment

      if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
        raise AssessmentGone
      end

      raise NotAnRdsap if assessment.to_hash[:type_of_assessment] != "RdSAP"

      assessment_xml =
        Nokogiri.XML(
          @assessments_xml_gateway.fetch(assessment_id)[:xml],
          &:noblanks
        )

      assessment_xml.remove_namespaces!

      REDACTED_TAGS.each do |redacted_tag|
        assessment_xml.search(".//#{redacted_tag}").remove
      end

      assessment_xml.to_xml(encoding: "utf-8")
    end
  end
end
