module UseCase
  class FetchSchemes
    def initialize
      @gateway = Gateway::SchemesGateway.new
    end

    def execute
      schemes = @gateway.all
      { schemes: }
    end
  end
end
