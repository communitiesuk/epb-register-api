module UseCase
  class GetAssessorsStatusEventsByDate
    class SchemeNotFoundException < StandardError
    end

    def initialize
      @assessors_status_events_gateway =
        Gateway::AssessorsStatusEventsGateway.new
    end

    def execute(date, scheme_id)
      @assessors_status_events_gateway.filter_by(date, scheme_id)
    end
  end
end
