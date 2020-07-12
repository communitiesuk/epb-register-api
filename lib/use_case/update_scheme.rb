module UseCase
  class UpdateScheme
    class SchemeNotFound < StandardError; end

    def initialize
      @gateway = Gateway::SchemesGateway.new
    end

    def execute(scheme_id, scheme_body)
      raise SchemeNotFound unless @gateway.exists?(scheme_id)

      @gateway.update(scheme_id, scheme_body)
    end
  end
end
