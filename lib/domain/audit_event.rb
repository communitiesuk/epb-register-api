module Domain
  class AuditEvent
    attr_reader :event_type, :entity_type, :data, :entity_id

    VALID_TYPES = {
      assessment: %i[
        lodgement
        opt_out
        opt_in
        cancelled
        address_id_updated
        green_deal_plan_added
        green_deal_plan_updated
        green_deal_plan_deleted
      ],
    }.freeze

    def initialize(event_type:, entity_id:, entity_type:, data: nil)
      validate(entity_type, event_type)

      @event_type = event_type
      @entity_id = entity_id
      @entity_type = entity_type
      @data = data
    end

  private

    def validate(entity_type, event_type)
      validate_entity_type(entity_type)
      validate_event_type(entity_type, event_type)
    end

    def validate_entity_type(entity_type)
      unless VALID_TYPES.key?(entity_type)
        raise ArgumentError, "Invalid entity_type"
      end
    end

    def validate_event_type(entity_type, event_type)
      unless VALID_TYPES[entity_type].include?(event_type)
        raise ArgumentError, "Invalid event_type for #{entity_type}"
      end
    end
  end
end
