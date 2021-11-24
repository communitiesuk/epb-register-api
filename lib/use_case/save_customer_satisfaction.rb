module UseCase
  class SaveCustomerSatisfaction
    def initialize(gateway)
      @gateway = gateway
    end

    def execute(satisfaction_object)
      raise Boundary::ArgumentMissing unless satisfaction_object.is_a?(Domain::CustomerSatisfaction)

      @gateway.upsert(satisfaction_object)
    end
  end
end
