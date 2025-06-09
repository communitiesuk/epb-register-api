module UseCase
  class ExportNiAssessments
    def initialize(export_ni_gateway:, xml_gateway:)
      @ni_export_gateway = export_ni_gateway
      @xml_gateway = xml_gateway
    end

    def execute(type_of_assessment:, date_from: "1990-01-01", date_to: Time.now)
      assessments_array = []

      if type_of_assessment =="SAP-RDSAP-RR"
        use_case = UseCase::ExportOpenDataDomesticrr.new
        assessments_array = use_case.execute(date_from, task_id, date_to, true)
      end

      assessments = @ni_export_gateway.fetch_assessments(type_of_assessment:, date_from:, date_to:)

      assessments.each do |assessment|
        xml_data = @xml_gateway.fetch(assessment["assessment_id"])

        view_model =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
          )

        view_model_data = type_of_assessment.any?{ |x| %w[CEPC DEC].include?(x) } ? view_model.to_report : view_model.to_hash_ni
        combined_data = view_model_data.merge(assessment.symbolize_keys)
        combined_data[:assessment_id] = Helper::RrnHelper.hash_rrn(assessment["assessment_id"])
        assessments_array << combined_data
      end
      assessments_array
    end
  end
end
