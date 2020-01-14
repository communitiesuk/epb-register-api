module UseCase
  class FindAssessors
    class PostcodeNotValid < Exception; end
    class PostcodeNotRegistered < Exception; end

    def initialize(postcodes_gateway, assessor_by_geolocation_gateway)
      @postcodes_gateway = postcodes_gateway
      @assessor_by_geolocation_gateway = assessor_by_geolocation_gateway
    end

    def execute(postcode)
      unless Regexp.new(
               '^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$',
               Regexp::IGNORECASE
             )
               .match(postcode)
        raise PostcodeNotValid
      end

      postcodes_geolocation = @postcodes_gateway.fetch(postcode)

      if postcodes_geolocation.size < 1
        raise PostcodeNotRegistered
      end

      latitude = postcodes_geolocation.first[:latitude]
      longitude = postcodes_geolocation.first[:longitude]

      { 'results': @assessor_by_geolocation_gateway.search(latitude, longitude), 'searchPostcode': postcode }
    end
  end
end
