module Domain
  class AssessmentStatusEvent
    def initialize(
      assessment_event:
    )
      @entity_id = assessment_event[:entity_id]
      @event_type = assessment_event[:event_type]
      @timestamp = assessment_event[:timestamp]
    end

    def to_hash
      {
        reportRrn: @entity_id,
        newStatus: get_new_status(@event_type),
        timestamp: @timestamp,
      }
    end

    def get_new_status(event_type)
      case event_type
      when "scottish_opt_out"
        "OPTED OUT"
      when "scottish_opt_in"
        "OPTED IN"
      when "scottish_cancelled"
        "CANCELLED"
      else
        "unknown event"
      end
    end
  end
end
