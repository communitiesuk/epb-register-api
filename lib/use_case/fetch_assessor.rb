module UseCase
  class FetchAssessor
    class AssessorNotFoundException < Exception; end

    def initialize(assessor_gateway, schemes_gateway)
      @assessor_gateway = assessor_gateway
      @schemes_gateway = schemes_gateway
    end

    def execute(scheme_id, scheme_assessor_id)
      scheme = @schemes_gateway.all.select do |scheme|
        scheme[:scheme_id].to_s == scheme_id.to_s
      end[0]

      if scheme[:scheme_id].to_s == scheme_id.to_s
        if @assessor_gateway.fetch(scheme_assessor_id) == nil
          raise AssessorNotFoundException
        end
        unless scheme_assessor_id == @assessor_gateway.fetch(scheme_assessor_id)[:scheme_assessor_id]
          raise AssessorNotFoundException
        end
        @assessor_gateway.fetch(scheme_assessor_id)
      else
        raise UseCase::AddAssessor::SchemeNotFoundException
      end
    end
  end
end
