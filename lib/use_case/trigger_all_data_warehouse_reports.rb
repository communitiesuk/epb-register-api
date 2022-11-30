# frozen_string_literal: true

module UseCase
  class TriggerAllDataWarehouseReports
    REPORTS = [:heat_pump_count_for_sap].freeze

    def initialize(individual_use_case:)
      @individual_use_case = individual_use_case
    end

    def execute
      REPORTS.each { |report| individual_use_case.execute report: }
    end

  private

    attr_reader :individual_use_case
  end
end
