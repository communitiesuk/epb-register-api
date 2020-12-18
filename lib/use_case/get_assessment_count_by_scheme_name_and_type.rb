module UseCase
  class GetAssessmentCountBySchemeNameAndType
    COMBINED_TYPES = {
      "AC-CERT" => "AC-REPORT+CERT",
      "AC-REPORT" => "AC-REPORT+CERT",
      "CEPC" => "CEPC+RR",
      "CEPC-RR" => "CEPC+RR",
      "DEC" => "DEC+RR",
      "DEC-RR" => "DEC+RR",
    }.freeze

    DEFAULT_COUNTS = {
      "AC-CERT" => 0,
      "AC-REPORT" => 0,
      "AC-REPORT+CERT" => 0,
      "CEPC" => 0,
      "CEPC+RR" => 0,
      "CEPC-RR" => 0,
      "DEC" => 0,
      "DEC+RR" => 0,
      "DEC-RR" => 0,
      "RdSAP" => 0,
      "SAP" => 0,
    }.freeze

    def initialize
      @reporting_gateway = Gateway::ReportingGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(start_date, end_date)
      assessments =
        @reporting_gateway.assessments_by_scheme_and_type start_date, end_date

      assessments_by_scheme_and_type = {}

      assessments.each do |data|
        type = data["type_of_assessment"]
        scheme = data["scheme_name"]
        linked = data["linked"]

        if assessments_by_scheme_and_type[scheme].nil?
          assessments_by_scheme_and_type[scheme] = DEFAULT_COUNTS.dup
        end

        type = COMBINED_TYPES[type] unless COMBINED_TYPES[type].nil? || linked.nil?

        assessments_by_scheme_and_type[scheme][type] += 1
      end

      assessments_invoicing = []

      assessments_by_scheme_and_type.each do |scheme, types|
        types.each do |type, count|
          assessments_invoicing <<
            {
              number_of_assessments: count,
              scheme_name: scheme,
              type_of_assessment: type,
            }
        end
      end

      assessments_invoicing
    end
  end
end
