module UseCase
  class FetchCustomerSatisfaction
    def initialize(gateway)
      @gateway = gateway
    end

    def execute
      @gateway.fetch
    end
  end
end
