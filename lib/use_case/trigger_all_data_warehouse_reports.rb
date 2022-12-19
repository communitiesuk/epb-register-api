# frozen_string_literal: true

module UseCase
  class TriggerAllDataWarehouseReports
    def initialize(reports_gateway:)
      @reports_gateway = reports_gateway
    end

    def execute
      reports_gateway.write_all_triggers
    end

  private

    attr_reader :reports_gateway
  end
end
