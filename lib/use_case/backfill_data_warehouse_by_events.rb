module UseCase
  class BackfillDataWarehouseByEvents
    def initialize(gateway:, data_warehouse_queues_gateway:)
      @gateway = gateway
      @data_warehouse_queues_gateway = data_warehouse_queues_gateway
    end

    def execute(event_type:, start_date:, end_date: Time.now)
      raise Boundary::InvalidDate if end_date < Time.parse(start_date)

      rrn_array = @gateway.fetch_assessment_ids(event_type:, start_date:, end_date:)

      raise Boundary::NoData, "No assessments to export for type #{event_type}" if rrn_array.count.zero?

      queue_name = event_type == "opt_in" ? "opt_out" : event_type

      rrn_array.map { |assessment_ids| assessment_ids }.each_slice(500) do |assessment_ids|
        @data_warehouse_queues_gateway.push_to_queue(queue_name.to_sym, assessment_ids)
      end
    end
  end
end
