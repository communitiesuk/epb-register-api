module UseCase
  class AssessmentMeta
    class NoDataException < StandardError; end


    def initialize(gateway)
      @gateway = gateway
    end

    def execute(assessment_id)
      result = @gateway.fetch(assessment_id)

      if result.nil?
        raise NoDataException
      else
        result
      end

    end
  end
end
