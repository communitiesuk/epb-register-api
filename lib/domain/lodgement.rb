# frozen_string_literal: true

require "json"

module Domain
  class Lodgement
    def self.schema(file)
      data = File.read File.join Dir.pwd, file

      JSON.parse(data).deep_transform_keys(&:to_sym)
    end

    SCHEMAS = {
      'RdSAP-Schema-19.0': {
        report_type: "RdSAP",
        schema_path:
          "api/schemas/xml/RdSAP-Schema-19.0/RdSAP/Templates/RdSAP-Report.xsd",
        data: schema("api/schemas/data/RdSAP-Schema-19.0.json"),
      },
      'SAP-Schema-17.1': {
        report_type: "SAP",
        schema_path:
          "api/schemas/xml/SAP-Schema-17.1/SAP/Templates/SAP-Report.xsd",
        data: schema("api/schemas/data/SAP-Schema-17.1.json"),
      },
      'SAP-Schema-NI-17.4': {
          report_type: "SAP",
          schema_path:
              "api/schemas/xml/SAP-Schema-NI-17.4/SAP/Templates/SAP-Report.xsd",
          data: schema("api/schemas/data/SAP-Schema-NI-17.4.json"),
      },
    }.freeze

    def initialize(data, schema_name)
      @data = data
      @schema_name = schema_name.to_sym
    end

    def schema_exists?
      SCHEMAS.key?(@schema_name)
    end

    def fetch_data(data = @data, schema = SCHEMAS[@schema_name][:data])
      Helper::DataExtractorHelper.new.fetch_data(data, schema)
    end

    def schema_path
      SCHEMAS[@schema_name][:schema_path]
    end

    def type
      SCHEMAS[@schema_name][:report_type]
    end
  end
end
