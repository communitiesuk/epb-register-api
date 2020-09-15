module Helper
  class SchemaListHelper
    class ValidationErrorException < StandardError; end

    def initialize(
      schema_name, schema_path = "api/schemas/data/orchestrate.json"
    )
      @schema_name = schema_name.to_sym
      @schema_path = schema_path

      data = File.read File.join Dir.pwd, @schema_path
      schema_variations = JSON.parse(data).deep_transform_keys(&:to_sym)

      @schema_active = schema_variations[@schema_name]
    end

    def schema_exists?
      @schema_active != nil
    end

    def schema_path
      @schema_active[:schema_path]
    end
  end
end
