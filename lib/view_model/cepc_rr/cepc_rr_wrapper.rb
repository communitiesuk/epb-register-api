module ViewModel
  module CepcRr
    class CepcRrWrapper
      TYPE_OF_ASSESSMENT = "CEPC-RR".freeze

      def initialize(xml, schema_type)
        case schema_type
        when "CEPC-8.0.0"
          @view_model = ViewModel::CepcRr::CepcRr800.new xml
        else
          raise ArgumentError, "Unsupported schema type"
        end
      end

      def type
        :CEPC_RR
      end

      def to_hash
        {
          type_of_assessment: TYPE_OF_ASSESSMENT,
          assessment_id: @view_model.assessment_id,
          report_type: @view_model.report_type,
          date_of_expiry: @view_model.date_of_expiry,
          address: {
            address_id: @view_model.address_id,
            address_line1: @view_model.address_line1,
            address_line2: @view_model.address_line2,
            address_line3: @view_model.address_line3,
            address_line4: @view_model.address_line4,
            town: @view_model.town,
            postcode: @view_model.postcode,
          },
          assessor: {
            scheme_assessor_id: @view_model.scheme_assessor_id,
            name: @view_model.assessor_name,
            contact_details: {
              email: @view_model.assessor_email,
              telephone: @view_model.assessor_telephone,
            },
            company_details: {
              name: @view_model.company_name,
              address: @view_model.company_address,
            },
          },
        }
      end
    end
  end
end
