module UseCase
  class FetchAssessorList
    def initialize(assessors_gateway)
      @assessors_gateway = assessors_gateway
    end

    def execute(scheme_id)
      @assessors_gateway.fetch_list(scheme_id)
    end
  end
end
