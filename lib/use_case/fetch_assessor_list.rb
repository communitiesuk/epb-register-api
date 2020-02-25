module UseCase
  class FetchAssessorList
    class SchemeNotFoundException < Exception; end

    def initialize(assessors_gateway, schemes_gateway)
      @assessors_gateway = assessors_gateway
      @schemes_gateway = schemes_gateway
    end

    def execute(scheme_id)
      raise SchemeNotFoundException unless @schemes_gateway.exists?(scheme_id)

      @assessors_gateway.fetch_list(scheme_id)
    end
  end
end
