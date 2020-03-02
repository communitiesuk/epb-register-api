module UseCase
  class FindAssessmentsByPostcode
    class PostcodeNotValid < Exception; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(postcode)
      postcode.upcase!

      postcode = postcode.insert(-4, ' ') if postcode[-4] != ' '

      unless Regexp.new(
               '^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$',
               Regexp::IGNORECASE
             )
               .match(postcode)
        raise PostcodeNotValid
      end

      result = @assessment_gateway.search_by_postcode(postcode)

      { 'results': result, 'searchQuery': postcode }
    end
  end
end
