module Domain
  class AuditEvent
    attr_reader :event_type, :entity_type, :data, :entity_id

    def initialize(event_type:, entity_id:, entity_type:, data: nil)
      @event_type = event_type
      @entity_id = entity_id
      @entity_type = entity_type
      @data = data
    end
  end
end
