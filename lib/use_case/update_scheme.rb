module UseCase
  class UpdateScheme
    class SchemeNotFound < StandardError; end

    def initialize
      @gateway = Gateway::SchemesGateway.new
    end

    def execute(scheme_id)
      raise SchemeNotFound unless @gateway.exists?(scheme_id)
    end
  end
end
