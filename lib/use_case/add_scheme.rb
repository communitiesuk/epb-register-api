module UseCase
  class AddScheme
    def initialize()
      @gateway = Gateway::SchemesGateway.new
    end

    def execute(name)
      @gateway.add(name)
    end
  end
end
