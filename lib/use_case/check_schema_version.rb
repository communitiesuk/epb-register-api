module UseCase
  class CheckSchemaVersion
    def initialize(logger: nil)
      @logger = logger || Logger.new($stdout)
    end

    def execute(schema_name)
      valid_schemas =  ENV["VALID_SCHEMAS"]
      if valid_schemas.nil?
        @logger.error("Schemas are not present in the param store")
        return false
      end
      valid_schemas.include?(schema_name)
    end
  end
end
