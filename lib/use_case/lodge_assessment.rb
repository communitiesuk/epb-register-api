# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    def initialize(domestic_energy_assessments_gateway, assessors_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(body, assessment_id, content_type)
      {}
    end
  end
end
