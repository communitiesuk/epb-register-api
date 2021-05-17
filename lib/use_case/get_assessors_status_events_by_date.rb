module UseCase
  class GetAssessorsStatusEventsByDate
    class SchemeNotFoundException < StandardError
    end

    def initialize
      @assessors_status_events_gateway =
        Gateway::AssessorsStatusEventsGateway.new
      @assessors_status_updated_events_gateway =
          Gateway::AssessorsStatusUpdatedEventsGateway.new
    end

    def execute(date)
      @assessors_status_events_gateway.filter_by(date)
    end

    def filter(date, scheme_id)

      @assessors_status_updated_events_gateway.filter_by(date, scheme_id)
    end
  end
end
