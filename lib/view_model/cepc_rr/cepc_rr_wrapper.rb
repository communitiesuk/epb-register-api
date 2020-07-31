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
        }
      end
    end
  end
end
