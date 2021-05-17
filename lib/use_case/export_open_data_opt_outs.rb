module UseCase
  class ExportOpenDataOptOuts
    def initialize(reporting_gateway)
      @reporting_gateway = reporting_gateway || Gateway::ReportingGateway.new
    end

    def execute(date_from, date_to = DateTime.now)
      array = []
      assessments =
        @reporting_gateway.fetch_opted_out_assessments(date_from, date_to)
      assessments.each do |assessment|
        array << {
          assessment_id: Helper::RrnHelper.hash_rrn(assessment["assessment_id"]),
        }
      end
      array
    end
  end
end
