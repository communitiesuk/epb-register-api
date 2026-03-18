module UseCase
  class FetchNewReports
    def initialize(new_reports_gateway)
      @new_reports_gateway = new_reports_gateway
    end

    def execute(start_date:, end_date:, current_page:, records_per_page: 5000)
      rrns = @new_reports_gateway.fetch(start_date:, end_date:, current_page:, limit: records_per_page)

      { rrns: rrns }
    end
  end
end
