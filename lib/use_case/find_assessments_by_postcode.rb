module UseCase
  class FindAssessmentsByPostcode
    class PostcodeNotValid < StandardError; end
    class ParameterMissing < StandardError; end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
    end

    def execute(postcode, assessment_types = [])
      postcode&.strip!&.upcase!

      raise ParameterMissing if postcode.blank?

      postcode = postcode.insert(-4, " ") if postcode[-4] != " "

      unless Regexp.new(Helper::RegexHelper::POSTCODE, Regexp::IGNORECASE)
               .match(postcode)
        raise PostcodeNotValid
      end

      result =
        @assessments_gateway.search_by_postcode(postcode, assessment_types)

      { data: result.map(&:to_hash), searchQuery: postcode }
    end
  end
end
