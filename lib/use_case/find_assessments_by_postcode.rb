module UseCase
  class FindAssessmentsByPostcode
    class PostcodeNotValid < StandardError; end

    def initialize(assessments_gateway)
      @assessments_gateway = assessments_gateway
    end

    def execute(postcode)
      postcode.upcase!

      postcode = postcode.insert(-4, " ") if postcode[-4] != " "

      unless Regexp.new(Helper::RegexHelper::POSTCODE, Regexp::IGNORECASE)
               .match(postcode)
        raise PostcodeNotValid
      end

      result = @assessments_gateway.search_by_postcode(postcode)

      { data: result.map(&:to_hash), searchQuery: postcode }
    end
  end
end
