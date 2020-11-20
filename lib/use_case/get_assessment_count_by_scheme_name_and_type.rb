module UseCase
  class GetAssessmentCountBySchemeNameAndType
    COMBINED_TYPES = {
      "AC-CERT" => { combined: "AC-REPORT+CERT", related: :related_rrn },
      "AC-REPORT" => { combined: "AC-REPORT+CERT", related: :related_rrn },
      "CEPC" => { combined: "CEPC+RR", related: :related_rrn },
      "CEPC-RR" => { combined: "CEPC+RR", related: :related_certificate },
      "DEC" => { combined: "DEC+RR", related: :related_rrn },
      "DEC-RR" => { combined: "DEC+RR", related: :related_rrn },
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
      assessments = @reporting_gateway.assessments_by_scheme_and_type start_date, end_date

      assessments_by_scheme_and_type = {}

      assessments.each do |data|
        rrn = data["assessment_id"]
        type = data["type_of_assessment"]
        scheme = data["scheme_name"]

        if assessments_by_scheme_and_type[scheme].nil?
          assessments_by_scheme_and_type[scheme] = DEFAULT_COUNTS.dup
        end

        if COMBINED_TYPES[type].nil?
          assessments_by_scheme_and_type[scheme][type] += 1
        else
          assessment_xml = Gateway::AssessmentsXmlGateway.new.fetch rrn
          view_model = ViewModel::Factory.new.create(
            assessment_xml[:xml],
            assessment_xml[:schema_type],
            rrn,
          ).get_view_model

          related = view_model.method(COMBINED_TYPES[type][:related]).call

          if related.nil?
            assessments_by_scheme_and_type[scheme][type] += 1
          elsif rrn > related
            assessments_by_scheme_and_type[scheme][COMBINED_TYPES[type][:combined]] += 1
          end
        end
      end

      assessments_invoicing = []

      assessments_by_scheme_and_type.each do |scheme, types|
        types.each do |type, count|
          assessments_invoicing << {
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
