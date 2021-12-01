module UseCase
  class FetchUserSatisfaction
    def initialize(gateway)
      @gateway = gateway
    end

    def execute
      @gateway.fetch
    end
  end
end
