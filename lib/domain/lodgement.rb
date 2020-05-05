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

    def fetch_data
      data = {}

      SCHEMAS[@schema_name][:data].each do |key, settings|
        settings[:path] = settings[:path].map(&:to_sym)

        path =
          if settings.key?(:root)
            root = settings[:root].to_sym

            SCHEMAS[@schema_name][:data][root][:path].map(&:to_sym)
          else
            []
          end

        path += settings[:path]

        data[key] = @data.dig(*path)
      end

      data
    end

    def extract(
      data,
      key = :improvements,
      target_domain = Domain::RecommendedImprovement
    )
      extractor = data[key]

      if extractor.nil?
        []
      else
        extractor = [extractor] unless extractor.is_a? Array

        extractor.map do |i|
          extractor_inner = { assessment_id: data[:assessment_id] }

          SCHEMAS[@schema_name][:data][key][:extract].each do |second_key, value|
            value[:path] =
              value[:path].is_a?(Array) ? value[:path].map(&:to_sym) : value[:path].to_sym

            extractor_inner[second_key] = i.dig(*value[:path])
          end

          extractor_inner[:sequence] = extractor_inner[:sequence].to_i

          target_domain.new(extractor_inner)
        end
      end
    end

    def schema_path
      SCHEMAS[@schema_name][:schema_path]
    end

    def type
      SCHEMAS[@schema_name][:report_type]
    end
  end
end
