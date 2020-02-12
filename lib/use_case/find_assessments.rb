module UseCase
  class FindAssessments
    class PostcodeNotValid < Exception; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(query)
      result = []

      uniform_query = transform_when_postcode(query)

      @assessment_gateway.search(
        uniform_query,
        Regexp.new('^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$', Regexp::IGNORECASE)
          .match(uniform_query)
      )
        .each do |assessment|
        assessment[:current_energy_efficiency_band] =
          get_energy_rating_band(assessment[:current_energy_efficiency_rating])
        assessment[:potential_energy_efficiency_band] =
          get_energy_rating_band(
            assessment[:potential_energy_efficiency_rating]
          )

        result.push(assessment)
      end
      { 'results': result, 'searchQuery': query }
    end

    private

    def get_energy_rating_band(number)
      case number
      when 1..20
        'g'
      when 21..38
        'f'
      when 39..54
        'e'
      when 55..68
        'd'
      when 69..80
        'c'
      when 81..91
        'b'
      when 92..100
        'a'
      end
    end

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
