# frozen_string_literal: true

module UseCase
  class CheckAssessorBelongsToScheme
    def initialize(assessors_gateway:)
      @assessors_gateway = assessors_gateway
    end

    def execute(scheme_assessor_id, scheme_ids)
      assessor = @assessors_gateway.fetch scheme_assessor_id

      raise Boundary::AssessorNotFoundException unless assessor

      scheme_ids.include? assessor.registered_by_id
    end
  end
end
