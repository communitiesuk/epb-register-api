module UseCase
  class FetchAssessorList
    class SchemeNotFoundException < Exception; end

    def initialize(schemes_gateway, assessors_gateway)
      @schemes_gateway = schemes_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(scheme_id)
      scheme =
        @schemes_gateway.all.select do |scheme|
          scheme[:scheme_id].to_s == scheme_id.to_s
        end.first

      raise SchemeNotFoundException unless scheme

      @assessors_gateway.fetch_list(scheme_id)
    end
  end
end
