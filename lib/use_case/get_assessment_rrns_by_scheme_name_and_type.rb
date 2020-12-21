module UseCase
  class GetAssessmentRrnsBySchemeNameAndType
    COMBINED_TYPES = {
      "AC-CERT" => "AC-REPORT+CERT",
      "AC-REPORT" => "AC-REPORT+CERT",
      "CEPC" => "CEPC+RR",
      "CEPC-RR" => "CEPC+RR",
      "DEC" => "DEC+RR",
      "DEC-RR" => "DEC+RR",
    }.freeze

    def initialize
      @reporting_gateway = Gateway::ReportingGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(start_date, end_date, scheme_id = nil)
      assessments =
        @reporting_gateway.assessments_by_scheme_and_type start_date,
                                                          end_date,
                                                          scheme_id

      assessments_invoicing = []

      assessments.each do |data|
        rrn = data["assessment_id"]
        type = data["type_of_assessment"]
        scheme = data["scheme_name"]
        linked = data["linked"]
        created_at = data["created_at"]

        type = COMBINED_TYPES[type] unless COMBINED_TYPES[type].nil? || linked.nil?

        assessments_invoicing <<
          {
            rrn: rrn,
            scheme_name: scheme,
            type_of_assessment: type,
            related_rrn: linked,
            lodged_at: created_at,
          }
      end

      assessments_invoicing
    end
  end
end
