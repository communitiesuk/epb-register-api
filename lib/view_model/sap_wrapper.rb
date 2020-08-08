module ViewModel
  class SapWrapper
    TYPE_OF_ASSESSMENT = "DEC".freeze

    def initialize(xml, schema_type)
      case schema_type
      when "SAP-Schema-18.0.0"
        @view_model = ViewModel::SapSchema1800::CommonSchema.new xml
      when "SAP-Schema-NI-18.0.0"
        @view_model = ViewModel::SapSchemaNi1800::CommonSchema.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def type
      :RdSAP
    end

    def to_hash
      { type_of_assessment: "SAP" }
    end

    def get_view_model
      @view_model
    end
  end
end
