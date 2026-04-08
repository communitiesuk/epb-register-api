module UseCase
  class AssessmentMeta
    class NoDataException < StandardError; end

    def initialize(gateway)
      @gateway = gateway
    end

    def execute(assessment_id, is_scottish: false)
      result = @gateway.fetch(assessment_id, is_scottish: is_scottish)

      if result.nil?
        raise NoDataException
      else
        result
      end
    end
  end
end
