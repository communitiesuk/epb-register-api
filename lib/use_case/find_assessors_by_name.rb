module UseCase
  class FindAssessorsByName
    class OnlyFirstNameGiven < StandardError
    end

    def initialize(assessor_gateway:)
      @assessor_gateway = assessor_gateway || Gateway::AssessorsGateway.new
    end

    def execute(name, qualification_type = nil, max_response_size = 20)
      raise OnlyFirstNameGiven if name.split.size < 2

      loose_match = false

      response = @assessor_gateway.search_by(name:, qualification_type:)

      if response.size <= max_response_size
        excluded = []
        response.each do |assessor|
          excluded.push(assessor[:scheme_assessor_id])
        end

        second_response =
          @assessor_gateway.search_by(
            name:,
            qualification_type:,
            loose_match: true,
            exclude: excluded,
          )

        (max_response_size - response.size).times do |index|
          next unless second_response[index]

          response.push(second_response[index])

          loose_match = true
        end
      end

      { data: response, search_name: name, loose_match: }
    end
  end
end
