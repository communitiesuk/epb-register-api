# frozen_string_literal: true

module Domain
  class Lodgement
    SCHEMAS = {
      'RdSAP-Schema-19.0': {
        schema_path:
          'api/schemas/xml/RdSAP-Schema-19.0/RdSAP/Templates/RdSAP-Report.xsd',
        scheme_assessor_id_location: %i[
          RdSAP_Report
          Report_Header
          Energy_Assessor
          Identification_Number
          Membership_Number
        ],
        data: {
          address: { path: %i[RdSAP_Report Report_Header Property Address] },
          address_line1: { root: :address, path: %i[Address_Line_1] },
          address_line2: { root: :address, path: %i[Address_Line_2] },
          address_line3: { root: :address, path: %i[Address_Line_3] },
          town: { root: :address, path: %i[Post_Town] },
          postcode: { root: :address, path: %i[Postcode] }
        }
      },
      'SAP-Schema-17.1': {
        schema_path:
          'api/schemas/xml/SAP-Schema-17.1/SAP/Templates/SAP-Report.xsd',
        scheme_assessor_id_location: %i[
          SAP_Report
          Report_Header
          Home_Inspector
          Identification_Number
          Certificate_Number
        ]
      }
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
        path =
          if settings.key?(:root)
            SCHEMAS[@schema_name][:data][settings[:root]][:path]
          else
            []
          end
        path += settings[:path]

        data[key] = @data.dig(*path)
      end

      data
    end

    def fetch_raw_data
      @data
    end

    def schema_path
      SCHEMAS[@schema_name][:schema_path]
    end

    def scheme_assessor_id
      @data.dig(*SCHEMAS[@schema_name][:scheme_assessor_id_location])
    end
  end
end
