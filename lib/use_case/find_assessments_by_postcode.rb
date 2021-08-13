module UseCase
  class FindAssessmentsByPostcode
    class PostcodeNotValid < StandardError
    end

    class ParameterMissing < StandardError
    end

    class AssessmentTypeNotValid < StandardError
    end

    def initialize
      @assessments_gateway = Gateway::AssessmentsSearchGateway.new
    end

    def execute(postcode, assessment_types = [])
      postcode&.strip!
      postcode&.upcase!

      raise ParameterMissing if postcode.blank?

      postcode = Helper::ValidatePostcodeHelper.new.validate_postcode(postcode)

      unless Regexp
               .new(Helper::RegexHelper::POSTCODE, Regexp::IGNORECASE)
               .match(postcode)
        raise PostcodeNotValid
      end

      result =
        @assessments_gateway.search_by_postcode(postcode, assessment_types)

      Helper::NaturalSort.sort!(result)

      { data: result.map(&:to_hash), searchQuery: postcode }
    rescue Gateway::AssessmentsSearchGateway::InvalidAssessmentType
      raise AssessmentTypeNotValid
    end
  end
end
