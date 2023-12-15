module UseCase
  class BackfillDataWarehouseByEvents
    EVENT_QUEUES = { cancelled: "cancelled",
                     opt_out: "opt_outs",
                     opt_in: "opt_outs",
                     address_id_updated: "assessments" }.freeze

    def initialize(audit_logs_gateway:, data_warehouse_queues_gateway:)
      @audit_logs_gateway = audit_logs_gateway
      @data_warehouse_queues_gateway = data_warehouse_queues_gateway
    end

    def execute(event_type:, start_date:, end_date: Time.now)
      raise Boundary::InvalidDate if end_date < Time.parse(start_date)

      rrns = @audit_logs_gateway.fetch_assessment_ids(event_type:, start_date:, end_date:)

      raise Boundary::NoData, "No assessments to export for type #{event_type}" if rrns.count.zero?

      queue_name = EVENT_QUEUES.select { |key, _value| key.to_s == event_type }.values.first

      rrns.each_slice(500) do |assessment_ids|
        @data_warehouse_queues_gateway.push_to_queue(queue_name.to_sym, assessment_ids)
      end
    end
  end
end
