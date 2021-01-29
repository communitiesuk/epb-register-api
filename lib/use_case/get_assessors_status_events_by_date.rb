module UseCase
  class GetAssessorsStatusEventsByDate
    class SchemeNotFoundException < StandardError
    end

    def initialize
      @assessors_status_events_gateway =
        Gateway::AssessorsStatusEventsGateway.new
    end

    def execute(date)
      @assessors_status_events_gateway.filter_by(date)
    end
  end
end
