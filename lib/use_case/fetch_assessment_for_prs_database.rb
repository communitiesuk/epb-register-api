module UseCase
  class FetchAssessmentForPrsDatabase
    class InvalidAssessmentTypeException < StandardError; end
    class InvalidUprnException < StandardError; end
    class AssessmentUnavailable < StandardError; end
    class NotFoundException < AssessmentUnavailable; end
    class AssessmentGone < AssessmentUnavailable; end

    def initialize(prs_database_gateway: nil)
      @prs_database_gateway = prs_database_gateway || Gateway::PrsDatabaseGateway.new
    end

    def execute(identifier:)
      if identifier.key?(:rrn)
        assessment_id = Helper::RrnHelper.normalise_rrn_format(identifier[:rrn])
        gateway_response = @prs_database_gateway.search_by_rrn(assessment_id)
        raise NotFoundException unless gateway_response
        raise InvalidAssessmentTypeException unless %w[RdSAP SAP].include? gateway_response["type_of_assessment"]

        if !gateway_response["not_for_issue_at"].nil? || !gateway_response["cancelled_at"].nil?
          raise AssessmentGone
        end

        response = Domain::AssessmentForPrsDatabaseDetails.new(
          gateway_response: gateway_response,
        )
      end

      if identifier.key?(:uprn)
        unless Regexp.new(Helper::RegexHelper::UPRN, Regexp::IGNORECASE).match(identifier[:uprn])
          raise InvalidUprnException.new("Invalid uprn pattern")
        end

        gateway_response = @prs_database_gateway.search_by_uprn(identifier[:uprn])
        raise NotFoundException unless gateway_response
        raise InvalidAssessmentTypeException unless %w[RdSAP SAP].include? gateway_response["type_of_assessment"]

        response = Domain::AssessmentForPrsDatabaseDetails.new(
          gateway_response: gateway_response,
        )
      end

      response
    end
  end
end
