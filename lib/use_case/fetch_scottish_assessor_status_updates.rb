module UseCase
  class FetchScottishAssessorStatusUpdates
    def initialize(assessor_status_events_gateway)
      @assessor_status_events_gateway = assessor_status_events_gateway
    end

    def execute(start_date:, end_date:, current_page:, records_per_page: 5000)
      events = @assessor_status_events_gateway.get_scottish_assessor_events(start_date:, end_date:, current_page:, limit: records_per_page)

      { statusUpdates: events }
    end
  end
end
