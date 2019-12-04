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
        else
          @assessor_gateway.fetch(scheme_assessor_id)
        end
      else
        'fail'
      end
    end
  end
end
