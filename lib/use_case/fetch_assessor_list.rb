module UseCase
  class FetchAssessorList
    class SchemeNotFoundException < StandardError; end

    def initialize
      @assessors_gateway = Gateway::AssessorsGateway.new
      @schemes_gateway = Gateway::SchemesGateway.new
    end

    def execute(scheme_id)
      raise SchemeNotFoundException unless @schemes_gateway.exists?(scheme_id)

      @assessors_gateway.fetch_list(scheme_id)
    end
  end
end
