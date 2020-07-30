module ViewModel
  module Cepc
    class CepcWrapper
      def initialize(xml, assessment_type)
        case assessment_type
        when "CEPC-8.0.0"
          @view_model = ViewModel::Cepc::Cepc800.new(xml)
        else
          raise ArgumentError.new("Unsupported assessment type")
        end
      end

      def to_hash
        {assessment_id: @view_model.assessment_id}
      end
    end
  end
end
