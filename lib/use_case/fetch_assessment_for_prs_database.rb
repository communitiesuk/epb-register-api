module UseCase
  class FetchAssessmentForPrsDatabase
    class InvalidAssessmentTypeException < StandardError; end
    class NotFoundException < StandardError; end

    def initialize(prs_database_gateway: nil)
      @prs_database_gateway = prs_database_gateway || Gateway::PrsDatabaseGateway.new
    end

    def execute(rrn: nil, uprn: nil)
      gateway_response =
        if rrn
          assessment_id = Helper::RrnHelper.normalise_rrn_format(rrn)
          @prs_database_gateway.search_by_rrn(assessment_id)
        elsif uprn
          @prs_database_gateway.search_by_uprn(uprn)
        end

      raise NotFoundException unless gateway_response
      raise InvalidAssessmentTypeException unless %w[RdSAP SAP].include? gateway_response["type_of_assessment"]

      Domain::AssessmentForPrsDatabaseDetails.new(gateway_response:)
    end
  end
end
