module UseCase
  class FetchRenewableHeatIncentive
    class NotFoundException < StandardError; end

    def initialize(renewable_heat_incentive_gateway)
      @renewable_heat_incentive_gateway = renewable_heat_incentive_gateway
    end

    def execute(assessment_id)
      renewable_heat_incentive =
        @renewable_heat_incentive_gateway.fetch(assessment_id)

      raise NotFoundException unless renewable_heat_incentive

      renewable_heat_incentive
    end
  end
end
