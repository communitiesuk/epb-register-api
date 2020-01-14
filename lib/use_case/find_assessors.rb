module UseCase
  class FindAssessors
    class PostcodeNotValid < Exception; end
    class PostcodeNotRegistered < Exception; end

    def initialize(postcodes_gateway, assessor_gateway)
      @postcodes_gateway = postcodes_gateway
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

      postcodes_geolocation = @postcodes_gateway.fetch(postcode)

      raise PostcodeNotRegistered if postcodes_geolocation.size < 1

      latitude = postcodes_geolocation.first[:latitude]
      longitude = postcodes_geolocation.first[:longitude]

      result = []
      @assessor_gateway.search(latitude, longitude).each do |assessor|
        result.push({ 'assessor': assessor, 'distance': assessor[:distance] })
      end

      { 'results': result, 'searchPostcode': postcode }
    end
  end
end
