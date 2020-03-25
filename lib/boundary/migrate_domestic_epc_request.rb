module Boundary
  class MigrateDomesticEpcRequest
    attr_reader :data, :assessment_id

    def initialize(assessment_id, data)
      @data = data
      @assessment_id = assessment_id
    end
  end
end
