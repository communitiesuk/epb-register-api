module UseCase
  class FetchAssessor
    class SchemeNotFoundException < Exception; end

    class AssessorNotFoundException < Exception; end

    def initialize(assessor_gateway, schemes_gateway)
      @assessor_gateway = assessor_gateway
      @schemes_gateway = schemes_gateway
    end

    def execute(scheme_id, scheme_assessor_id)
      assessor = @assessor_gateway.fetch(scheme_assessor_id)
      unless assessor && assessor.registered_by_id.to_s == scheme_id.to_s
        raise AssessorNotFoundException
      end

      raise SchemeNotFoundException unless @schemes_gateway.exists?(scheme_id)
      assessor.to_hash
    end
  end
end
