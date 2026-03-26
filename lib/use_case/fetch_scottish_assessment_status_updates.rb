module UseCase
  class FetchScottishAssessmentStatusUpdates
    def initialize(audit_logs_gateway)
      @audit_logs_gateway = audit_logs_gateway
    end

    def execute(start_date:, end_date:, current_page:, records_per_page: 5000)
      event_types = %w[scottish_opt_out scottish_opt_in scottish_cancelled]
      events = @audit_logs_gateway.fetch_scottish_events(event_types:, start_date:, end_date:, current_page:, limit: records_per_page)

      { statusUpdates: events }
    end
  end
end
