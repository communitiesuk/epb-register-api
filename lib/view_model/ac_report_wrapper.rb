module ViewModel
  class AcReportWrapper
    TYPE_OF_ASSESSMENT = "AC-REPORT".freeze

    def initialize(xml, schema_type)
      case schema_type
      when "CEPC-8.0.0"
        @view_model = ViewModel::Cepc800::AcReport.new xml
      when "CEPC-NI-8.0.0"
        @view_model = ViewModel::CepcNi800::AcReport.new xml
      when "CEPC-7.1"
        @view_model = ViewModel::Cepc71::AcReport.new xml
      when "CEPC-7.0"
        @view_model = ViewModel::Cepc70::AcReport.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def type
      :AC_REPORT
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
        related_party_disclosure: @view_model.related_party_disclosure,
        assessor: {
          scheme_assessor_id: @view_model.scheme_assessor_id,
          name: @view_model.assessor_name,
          contact_details: {
            email: @view_model.assessor_email,
            telephone: @view_model.assessor_telephone,
          },
          company_details: {
            name: @view_model.company_name, address: @view_model.company_address
          },
        },
        executive_summary: @view_model.executive_summary,
        equipment_owner: {
            name: @view_model.equipment_owner_name,
            telephone: @view_model.equipment_owner_telephone,
            organisation: @view_model.equipment_owner_organisation,
            address: {
                address_line1: @view_model.equipment_owner_address_line1,
                address_line2: @view_model.equipment_owner_address_line2,
                address_line3: @view_model.equipment_owner_address_line3,
                address_line4: @view_model.equipment_owner_address_line4,
                town: @view_model.equipment_owner_town,
                postcode: @view_model.equipment_owner_postcode,
            }
        },
        equipment_operator: {
            responsible_person: @view_model.operator_responsible_person,
            telephone: @view_model.operator_telephone,
            organisation: @view_model.operator_organisation,
            address: {
                address_line1: @view_model.operator_address_line1,
                address_line2: @view_model.operator_address_line2,
                address_line3: @view_model.operator_address_line3,
                address_line4: @view_model.operator_address_line4,
                town: @view_model.operator_town,
                postcode: @view_model.operator_postcode,
            }
        }
      }
    end

    def get_view_model
      @view_model
    end
  end
end
