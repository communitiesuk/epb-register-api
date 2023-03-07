# frozen_string_literal: true

require "redis"

module Gateway
  class DataWarehouseReportsGateway
    REPORTS = [:heat_pump_count_for_sap].freeze

    def initialize(redis_client: nil)
      @redis = redis_client
    end

    def write_trigger(report:)
      redis.sadd :report_triggers, report
    end

    def write_triggers(reports:)
      redis.sadd :report_triggers, reports
    end

    def write_all_triggers
      redis.sadd :report_triggers, REPORTS
    end

    def reports
      reports_array = redis.hgetall(:reports).reduce([]) do |report_list, (name, value)|
        JSON.parse(value, symbolize_names: true) => {data:, date_created: generated_at}
        report_list << Domain::DataWarehouseReport.new(name: name.to_sym, data:, generated_at:)
      end

      Domain::DataWarehouseReportCollection.new(
        reports_array,
        incomplete: !(REPORTS - reports_array.map(&:name)).empty?,
      )
    end

    def known_reports
      REPORTS
    end

  private

    def redis
      return @redis if @redis

      @redis = DataWarehouseRedisHelper.redis
    end
  end
end
