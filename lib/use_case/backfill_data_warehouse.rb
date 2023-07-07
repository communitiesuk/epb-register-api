module UseCase
  class BackfillDataWarehouse
    def initialize(backfill_gateway:, data_warehouse_queues_gateway:)
      @backfill_gateway = backfill_gateway
      @data_warehouse_queues_gateway = data_warehouse_queues_gateway
    end

    def execute(rrn:, start_date:, schema_type:)
      result = @backfill_gateway.get_rrn_date(rrn)
      raise Boundary::NoData, "No assessment for this rrn" if result.count.zero?

      rrn_date = result.first["date_registered"]
      raise Boundary::InvalidDate if rrn_date < Time.parse(start_date)

      assessment_count = @backfill_gateway.count_assessments_to_export(rrn_date, start_date, schema_type)
      raise Boundary::NoData, "No assessments to export" if assessment_count.zero?

      is_dry_run = ENV["dry_run"] != "false"

      if is_dry_run
        puts "#{assessment_count} assessments would be exported out to the data warehouse queue."
        puts "To run this export, run this command again with a dry_run=false option declared."
        assessment_count
      else
        puts "Exporting #{assessment_count} assessments out to the data warehouse queue..."
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        list_of_assessments = @backfill_gateway.get_assessments_id(rrn_date:, start_date:, schema_type:)
        list_of_assessments.map { |assessment_ids| assessment_ids }.each_slice(500) do |assessment_ids|
          @data_warehouse_queues_gateway.push_to_queue(:assessments, assessment_ids)
        end
        seconds_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
        puts "Pushed #{assessment_count} assessments out to the data warehouse queue in #{seconds_elapsed}s."
      end
    end
  end
end
