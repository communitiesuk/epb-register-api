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
        assessment[:current_energy_efficiency_band] =
          get_energy_rating_band(assessment[:current_energy_efficiency_rating])
        assessment[:potential_energy_efficiency_band] =
          get_energy_rating_band(assessment[:potential_energy_efficiency_rating])

        result.push(assessment)
      end
      { 'results': result, 'searchPostcode': postcode }
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
  end
end
