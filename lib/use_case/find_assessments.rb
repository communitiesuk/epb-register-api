module UseCase
  class FindAssessments
    class PostcodeNotValid < Exception; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(query)
      uniform_query = transform_when_postcode(query)

      if Regexp.new('^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$', Regexp::IGNORECASE)
           .match(uniform_query)
        result = @assessment_gateway.search_by_postcode(uniform_query)
      else
        result = @assessment_gateway.search_by_assessment_id(uniform_query)
      end

      { 'results': result, 'searchQuery': query }
    end

    private

    def transform_when_postcode(query)
      potential_postcode = query.upcase

      if potential_postcode[-4] != ' '
        potential_postcode = potential_postcode.insert(-4, ' ')
      end

      if Regexp.new('^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$', Regexp::IGNORECASE)
           .match(potential_postcode)
        return potential_postcode
      end

      query
    end
  end
end
