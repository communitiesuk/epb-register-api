module UseCase
  class ExportOpenDataOptOuts
    def initialize(reporting_gateway)
      @reporting_gateway = reporting_gateway || Gateway::ReportingGateway.new
    end

    def execute
      array = []
      assessments = @reporting_gateway.fetch_opted_out_assessments
      assessments.each do |assessment|
        array << {
          assessment_id: Helper::RrnHelper.hash_rrn(assessment["assessment_id"]),
        }
      end
      array
    end
  end
end
