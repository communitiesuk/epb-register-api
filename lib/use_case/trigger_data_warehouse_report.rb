# frozen_string_literal: true

module UseCase
  class TriggerDataWarehouseReport
    def initialize(reports_gateway:)
      @reports_gateway = reports_gateway
    end

    def execute(report:)
      reports_gateway.write_trigger report:
    end

  private

    attr_reader :reports_gateway
  end
end
