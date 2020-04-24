module Domain
  class Lodgement
    @@schemas = {
      'RdSAP-Schema-19.0': {
        schema_path: 'api/schemas/xml/RdSAP-Schema-19.0/RdSAP/Templates/RdSAP-Report.xsd',
        scheme_assessor_id_location: %i[
            RdSAP_Report
            Report_Header
            Energy_Assessor
            Identification_Number
            Membership_Number
          ],

      },
      'SAP-Schema-17.1': {
        schema_path: 'api/schemas/xml/SAP-Schema-17.1/SAP/Templates/SAP-Report.xsd',
        scheme_assessor_id_location: %i[
            SAP_Report
            Report_Header
            Home_Inspector
            Identification_Number
            Certificate_Number
          ],

      }
    }.freeze

    def initialize(data, schema_name)
      @data = data

      @schema_name = schema_name.to_sym
    end

    def schema_exists
      @@schemas.has_key?(@schema_name)
    end

    def get_data
      @data
    end

    def schema_path
      @@schemas[@schema_name][:schema_path]
    end

    def scheme_assessor_id
      @data.dig(*@@schemas[@schema_name][:scheme_assessor_id_location])
    end
  end
end
