module UseCase
  class FindAssessments
    class PostcodeNotValid < Exception; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(postcode)
      unless Regexp.new(
               '^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$',
               Regexp::IGNORECASE
             )
               .match(postcode)
        raise PostcodeNotValid
      end

      result = []
      @assessment_gateway.search(postcode).each do |assessment|
        result.push(assessment)
      end
      { 'results': result, 'searchPostcode': postcode }
    end
  end
end
