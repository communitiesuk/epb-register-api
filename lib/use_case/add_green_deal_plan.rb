module UseCase
  class AddGreenDealPlan
    class NotFoundException < StandardError; end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
    end

    def execute(assessment_id)
      assessments = @assessments_gateway.search_by_assessment_id assessment_id

      raise NotFoundException unless assessments.first
    end
  end
end
