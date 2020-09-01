module UseCase
  class FindAssessorsByName
    class OnlyFirstNameGiven < StandardError; end

    def initialize
      @assessor_gateway = Gateway::AssessorsGateway.new
      @schemes_gateway = Gateway::SchemesGateway.new
    end

    def execute(name, max_response_size = 20)
      raise OnlyFirstNameGiven if name.split.size < 2

      schemes = []

      @schemes_gateway.all.each do |scheme|
        schemes[scheme[:scheme_id].to_i] = scheme
      end

      loose_match = false

      response = @assessor_gateway.search_by(name: name, max_response_size: 0)

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
            exclude: excluded,
          )

        (max_response_size - response.size).times do |index|
          next unless second_response[index]

          response.push(second_response[index])

          loose_match = true
        end
      end

      { data: response, search_name: name, loose_match: loose_match }
    end
  end
end
