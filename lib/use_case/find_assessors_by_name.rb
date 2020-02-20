module UseCase
  class FindAssessorsByName
    class TooManyResults < Exception; end

    def initialize(assessor_gateway, schemes_gateway)
      @assessor_gateway = assessor_gateway
      @schemes_gateway = schemes_gateway
    end

    def execute(name, max_response_size = 20)
      schemes = []

      @schemes_gateway.all.each do |scheme|
        schemes[scheme[:scheme_id].to_i] = scheme
      end

      result = []

      response =
        @assessor_gateway.search_by(
          name: name, max_response_size: max_response_size
        )

      if response.size <= max_response_size
        excluded = []
        response.each do |assessor|
          excluded.push(assessor[:scheme_assessor_id])
        end

        second_response =
          @assessor_gateway.search_by(
            name: name,
            max_response_size: 0,
            loose_match: true,
            exclude: excluded
          )

        (max_response_size - response.size).times do |index|
          response.push(second_response[index]) if second_response[index]
        end
      end

      response.each do |assessor|
        scheme = schemes[assessor[:registered_by].to_i]
        assessor[:registered_by] = scheme
        result.push(assessor)
      end

      { 'results': result, 'searchName': name }
    rescue Gateway::AssessorsGateway::TooManyResults
      raise TooManyResults
    end
  end
end
