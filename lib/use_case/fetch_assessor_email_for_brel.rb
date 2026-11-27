module UseCase
  class FetchAssessorEmailForBrel
    def initialize(assessor_gateway: nil)
      @assessor_gateway = assessor_gateway || Gateway::AssessorsGateway.new
    end

    def execute(scheme_assessor_id)
      assessor = @assessor_gateway.fetch(scheme_assessor_id)

      unless assessor
        return {}
      end

      unless assessor.domestic_sap_qualification == "ACTIVE"
        return {}
      end

      { email: assessor.email }
    end
  end
end
