module ViewModel
  module Cepc
    class CepcWrapper
      def initialize(xml, schema_type)
        case schema_type
        when "CEPC-8.0.0"
          @view_model = ViewModel::Cepc::Cepc800.new(xml)
        else
          raise ArgumentError, "Unsupported assessment type"
        end
      end

      def to_hash
        { assessment_id: @view_model.assessment_id }
      end
    end
  end
end
