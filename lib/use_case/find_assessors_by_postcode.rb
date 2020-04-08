module UseCase
  class FindAssessorsByPostcode
    class PostcodeNotValid < StandardError; end
    class PostcodeNotRegistered < StandardError; end

    def initialize(postcodes_gateway, assessor_gateway, schemes_gateway)
      @postcodes_gateway = postcodes_gateway
      @assessor_gateway = assessor_gateway
      @schemes_gateway = schemes_gateway
    end

    def execute(postcode, qualifications)
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

      schemes = []

      @schemes_gateway.all.each do |scheme|
        schemes[scheme[:scheme_id]] = scheme
      end

      result = @assessor_gateway.search(latitude, longitude, qualifications)

      {
        'data': { 'assessors': result }, 'meta': { 'searchPostcode': postcode }
      }
    end
  end
end
