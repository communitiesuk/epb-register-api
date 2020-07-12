module UseCase
  class AddScheme
    def initialize
      @gateway = Gateway::SchemesGateway.new
    end

    def execute(scheme_body)
      @gateway.add(scheme_body)
    end
  end
end
