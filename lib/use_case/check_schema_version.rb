module UseCase
  class CheckSchemaVersion
    def initialize(logger: nil)
      @logger = logger || Logger.new($stdout)
    end

    def execute(schema_name)
      valid_domestic_schemas = ENV["VALID_DOMESTIC_SCHEMAS"]
      valid_non_domestic_schemas = ENV["VALID_NON_DOMESTIC_SCHEMAS"]
      if valid_domestic_schemas.nil? && valid_non_domestic_schemas.nil?
        @logger.error("Both domestic and non domestic schemas are not present in the param store")
        return false
      end
      valid_schemas = valid_domestic_schemas + valid_non_domestic_schemas
      valid_schemas.include?(schema_name)
    end
  end
end
