module ViewModel
  class AcCertWrapper
    TYPE_OF_ASSESSMENT = "AC-CERT".freeze

    def initialize(xml, schema_type)
      case schema_type
      when "CEPC-8.0.0"
        @view_model = ViewModel::Cepc800::AcCert.new xml
      when "CEPC-NI-8.0.0"
        @view_model = ViewModel::CepcNi800::AcCert.new xml
      when "CEPC-7.0"
        @view_model = ViewModel::Cepc70::AcCert.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def type
      :AC_CERT
    end

    def to_hash
      {
        type_of_assessment: TYPE_OF_ASSESSMENT,
        assessment_id: @view_model.assessment_id,
        report_type: @view_model.report_type,
        date_of_expiry: @view_model.date_of_expiry,
        address: {
          address_line1: @view_model.address_line1,
          address_line2: @view_model.address_line2,
          address_line3: @view_model.address_line3,
          address_line4: @view_model.address_line4,
          town: @view_model.town,
          postcode: @view_model.postcode,
        },
        technical_information: {
          date_of_assessment: @view_model.date_of_assessment,
          building_complexity: @view_model.building_complexity,
          calculation_tool: @view_model.calculation_tool,
          f_gas_compliant_date: @view_model.f_gas_compliant_date,
          ac_rated_output: @view_model.ac_rated_output,
          random_sampling: @view_model.random_sampling,
          treated_floor_area: @view_model.treated_floor_area,
          ac_system_metered: @view_model.ac_system_metered,
        },
      }
    end

    def get_view_model
      @view_model
    end
  end
end
