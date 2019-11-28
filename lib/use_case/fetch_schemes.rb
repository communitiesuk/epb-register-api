module UseCase
  class FetchSchemes
    def initialize(gateway)
      @gateway = gateway
    end

    def execute
      schemes = @gateway.all
      { schemes: schemes }
    end
  end
end
