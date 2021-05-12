module UseCase
  class ExportAssessmentAttributes
    def initialize(assessment_gateway, xml_gateway)
      @assessment_gateway = assessment_gateway
      @xml_gateway = xml_gateway
    end

    def execute(date_from, date_to = DateTime.now)
      assessments = []
      assessments_ids =
        @assessment_gateway.fetch_assessment_ids_by_range(date_from, date_to)

      assessments_ids.each do |_assessment|
        xml_data = @xml_gateway.fetch(_assessment["assessment_id"])

        export_view_model =
          get_export_object(
            xml_data[:xml],
            _assessment["type_of_assessment"],
            xml_data[:schema_type],
          )

        assessments << {
          assessment_id: _assessment["assessment_id"],
          type_of_assessment: _assessment["type_of_assessment"],
          xml: xml_data[:xml],
        }
      end

      assessments
    end

  private

    def get_export_object(xml, type_of_assessment, schema_type)
      wrapper = ViewModel::Factory.new.create(xml.to_s, schema_type)
      case type_of_assessment.upcase
      when "CEPC"
        ViewModel::Export::CommercialExportView.new(wrapper, xml)
      when "RDSAP"
        ViewModel::Export::DomesticExportView.new(wrapper, xml)
      end
    end
  end
end
