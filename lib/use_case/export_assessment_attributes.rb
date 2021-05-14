module UseCase
  class ExportAssessmentAttributes
    def initialize(assessment_gateway, assessment_search_gateway, xml_gateway)
      @assessment_gateway = assessment_gateway
      @assessment_search_gateway = assessment_search_gateway
      @xml_gateway = xml_gateway
    end

    def execute(date_from, date_to = DateTime.now)
      assessments = []
      assessments_ids =
        @assessment_gateway.fetch_assessment_ids_by_range(date_from, date_to)

      assessments_ids.each do |assessment|
        xml_data = @xml_gateway.fetch(assessment["assessment_id"])
        assessment_data = @assessment_search_gateway.search_by_assessment_id(assessment["assessment_id"])

        export_view = get_export_view(
          xml_data[:xml],
          assessment_data,
          assessment["type_of_assessment"],
          xml_data[:schema_type],
        )

        unless export_view.nil?
          assessments << {
            assessment_id: assessment["assessment_id"],
            type_of_assessment: assessment["type_of_assessment"],
            data: export_view.build
          }
        end
      end
      assessments
    end

    private

    def get_export_view(xml, assessment, type_of_assessment, schema_type)
      wrapper = ViewModel::Factory.new.create(xml.to_s, schema_type)
      case type_of_assessment.upcase
      when "CEPC"
        ViewModel::Export::CommercialExportView.new(wrapper, assessment)
      when "SAP"
        ViewModel::Export::DomesticExportView.new(wrapper, assessment)
      when "RDSAP"
        ViewModel::Export::DomesticExportView.new(wrapper, assessment)
      else
        nil
      end
    end
  end
end
