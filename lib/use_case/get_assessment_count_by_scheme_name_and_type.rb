module UseCase
  class GetAssessmentCountBySchemeNameAndType
    def initialize
      @reporting_gateway = Gateway::ReportingGateway.new
    end

    def execute(start_date, end_date)
      @reporting_gateway.assessments_by_scheme_and_type(start_date, end_date)
    end
  end
end
