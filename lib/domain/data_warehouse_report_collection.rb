# frozen_string_literal: true

require "forwardable"

module Domain
  class DataWarehouseReportCollection
    include Enumerable
    extend Forwardable

    def initialize(*reports, incomplete: false)
      @reports = reports.flatten
      @incomplete = incomplete
    end

    def_delegator :@reports, :each

    def incomplete?
      @incomplete
    end
  end
end
