module UseCase
  class FetchAssessor
    class SchemeNotFoundException < Exception; end

    class AssessorNotFoundException < Exception; end

    def initialize(assessor_gateway, schemes_gateway)
      @assessor_gateway = assessor_gateway
      @schemes_gateway = schemes_gateway
    end

    def execute(scheme_id, scheme_assessor_id)
      assessor = @assessor_gateway.fetch(scheme_assessor_id).dup
      unless assessor && assessor[:registered_by].to_s == scheme_id.to_s
        raise AssessorNotFoundException
      end

      scheme =
        @schemes_gateway.all.select do |scheme|
          scheme[:scheme_id].to_s == scheme_id.to_s
        end[
          0
        ]
      raise SchemeNotFoundException unless scheme
      assessor[:registered_by] = scheme
      assessor
    end
  end
end
