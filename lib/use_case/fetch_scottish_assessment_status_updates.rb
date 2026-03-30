module UseCase
  class FetchScottishAssessmentStatusUpdates
    def initialize(audit_logs_gateway)
      @audit_logs_gateway = audit_logs_gateway
    end

    def execute(start_date:, end_date:, current_page:, event_types:, records_per_page: 5000)
      events = @audit_logs_gateway.fetch_scottish_events(event_types:, start_date:, end_date:, current_page:, limit: records_per_page)

      { statusUpdates: events }
    end
  end
end
