module UseCase
  class GetAssessmentCountByRegionAndType
    def initialize
      @reporting_gateway = Gateway::ReportingGateway.new
    end

    def execute(start_date, end_date)
      @reporting_gateway.assessments_by_region_and_type(start_date, end_date)
    end
  end
end
