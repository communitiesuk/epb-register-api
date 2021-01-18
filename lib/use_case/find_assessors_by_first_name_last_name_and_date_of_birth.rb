module UseCase
  class FindAssessorsByFirstNameLastNameAndDateOfBirth

    def initialize
      @assessor_gateway = Gateway::AssessorsGateway.new
    end

    def execute(first_name, last_name, date_of_birth)
      @assessor_gateway.search_by_first_name_last_name_and_date_of_birth(first_name, last_name, date_of_birth)
    end

  end
end
