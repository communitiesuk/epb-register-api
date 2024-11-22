module UseCase
  class BackfillDataWarehouse
    def initialize(backfill_gateway:, data_warehouse_queues_gateway:)
      @backfill_gateway = backfill_gateway
      @data_warehouse_queues_gateway = data_warehouse_queues_gateway
    end

    def execute(start_date:, type_of_assessment: nil, end_date: Time.now.utc)
      raise Boundary::InvalidDate if end_date < Time.parse(start_date)

      rrn_array = @backfill_gateway.get_assessments_id(start_date:, type_of_assessment:, end_date:)
      raise Boundary::NoData, "No assessments to export" if rrn_array.count.zero?

      puts "Exporting #{rrn_array.count} assessments out to the data warehouse queue..."

      rrn_array.map { |assessment_ids| assessment_ids }.each_slice(500) do |assessment_ids|
        @data_warehouse_queues_gateway.push_to_queue(:assessments, assessment_ids)
      end
    end
  end
end
