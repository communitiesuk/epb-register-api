module UseCase
  class FindAssessors
    class PostcodeNotValid < Exception; end

    def initialize(schemes_gateway, assessor_gateway)
      @schemes_gateway = schemes_gateway
      @assessor_gateway = assessor_gateway
    end

    def execute(postcode)
      unless Regexp.new(
               '^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$',
               Regexp::IGNORECASE
             )
               .match(postcode)
        raise PostcodeNotValid
      end
      
      {
        'results': @assessor_gateway.fetch,
        'searchPostcode': postcode
      }
    end
  end
end
