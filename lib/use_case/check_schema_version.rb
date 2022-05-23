module UseCase
  class CheckSchemaVersion
    def initialize(logger: nil)
      @logger = logger || Logger.new($stdout)
    end

    def execute(schema_name)
      valid_schemas.include?(schema_name)
    end

  private

    def valid_schemas
      @valid_schemas ||= ValidSchemaList.new logger: @logger
    end

    # The valid schemas are provided as comma-separated lists
    # Example string:
    #   CEPC-8.0.0,CEPC-NI-8.0.0
    #
    class ValidSchemaList
      def initialize(logger: nil)
        valid_domestic_schemas = ENV["VALID_DOMESTIC_SCHEMAS"]&.split(",") || []
        valid_non_domestic_schemas = ENV["VALID_NON_DOMESTIC_SCHEMAS"]&.split(",") || []
        @valid_schemas = (valid_domestic_schemas + valid_non_domestic_schemas).map(&:strip)
        if @valid_schemas.empty?
          logger.error("No valid schemas! Are the VALID_*_SCHEMAS environment variables set?")
        end
      end

      def include?(schema_name)
        @valid_schemas.include?(schema_name)
      end
    end
  end
end
