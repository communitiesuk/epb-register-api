module UseCase
  class CheckAssessorBelongsToScheme
    class AssessorNotFoundException < StandardError; end

    def initialize(assessor_gateway)
      @assessor_gateway = assessor_gateway
    end

    def execute(scheme_assessor_id, scheme_ids)
      assessor = @assessor_gateway.fetch(scheme_assessor_id)
      raise AssessorNotFoundException unless assessor
      scheme_ids.include?(assessor.registered_by_id)
    end
  end
end
