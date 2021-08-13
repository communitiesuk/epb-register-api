module UseCase
  class FindAssessorsByPostcode
    class PostcodeNotValid < StandardError
    end

    class PostcodeNotRegistered < StandardError
    end

    def initialize
      @postcodes_gateway = Gateway::PostcodesGateway.new
      @assessor_gateway = Gateway::AssessorsGateway.new
    end

    def execute(postcode, qualifications)
      postcode&.strip!
      postcode&.upcase!

      unless Regexp
               .new(Helper::RegexHelper::POSTCODE, Regexp::IGNORECASE)
               .match(postcode)
        raise PostcodeNotValid
      end

      postcodes_geolocation = @postcodes_gateway.fetch(postcode)

      raise PostcodeNotRegistered if postcodes_geolocation.empty?

      latitude = postcodes_geolocation.first[:latitude]
      longitude = postcodes_geolocation.first[:longitude]

      result = @assessor_gateway.search(latitude, longitude, qualifications)

      { data: result, search_postcode: postcode }
    end
  end
end
