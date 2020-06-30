module UseCase
  class FetchRenewableHeatIncentive
    class NotFoundException < StandardError; end
    class AssessmentGone < StandardError; end

    def initialize(renewable_heat_incentive_gateway)
      @renewable_heat_incentive_gateway = renewable_heat_incentive_gateway
    end

    def execute(assessment_id)
      renewable_heat_incentive =
        @renewable_heat_incentive_gateway.fetch assessment_id

      raise NotFoundException unless renewable_heat_incentive

      renewable_heat_incentive = renewable_heat_incentive.to_hash

      if renewable_heat_incentive.delete :is_cancelled
        raise AssessmentGone
      end

      renewable_heat_incentive
    end
  end
end
