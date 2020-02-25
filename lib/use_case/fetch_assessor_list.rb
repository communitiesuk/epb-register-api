module UseCase
  class FetchAssessorList
    class SchemeNotFoundException < Exception; end

    def initialize(schemes_gateway)
      @schemes_gateway = schemes_gateway
    end

    def execute(scheme_id)
      scheme =
        @schemes_gateway.all.select do |scheme|
          scheme[:scheme_id].to_s == scheme_id.to_s
        end.first

      raise SchemeNotFoundException unless scheme
    end
  end
end
