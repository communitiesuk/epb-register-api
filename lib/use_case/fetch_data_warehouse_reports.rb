# frozen_string_literal: true

module UseCase
  class FetchDataWarehouseReports
    def initialize(reports_gateway:)
      @reports_gateway = reports_gateway
    end

    def execute
      report_collection = reports_gateway.reports
      if report_collection.incomplete?
        reports_gateway.write_triggers reports: (reports_gateway.known_reports - report_collection.map(&:name))
      end

      report_collection
    end

  private

    attr_reader :reports_gateway
  end
end
