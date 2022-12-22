# frozen_string_literal: true

module Domain
  class AssessmentReference
    def initialize(rrn:)
      raise ArgumentError, "RRN #{rrn} has an incorrect format" unless Helper::RrnHelper.valid_format?(rrn)

      @rrn = rrn
    end

    attr_reader :rrn
  end
end
