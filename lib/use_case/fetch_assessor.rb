module UseCase
  class FetchAssessor
    class SchemeNotFoundException < StandardError
    end

    class AssessorNotFoundException < StandardError
    end

    def initialize
      @assessor_gateway = Gateway::AssessorsGateway.new
      @schemes_gateway = Gateway::SchemesGateway.new
    end

    def execute(scheme_id, scheme_assessor_id)
      assessor = @assessor_gateway.fetch(scheme_assessor_id)
      unless assessor && assessor.registered_by_id.to_s == scheme_id.to_s
        raise AssessorNotFoundException
      end

      raise SchemeNotFoundException unless @schemes_gateway.exists?(scheme_id)

      assessor
    end
  end
end
