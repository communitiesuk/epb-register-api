module UseCase
  class FetchGreenDealAssessment
    class UnauthorisedToFetchThisAssessment < StandardError; end
    class NotFoundException < StandardError; end

    def initialize
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(assessment_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      unless assessment_xml = @assessments_xml_gateway.fetch(assessment_id)
        raise NotFoundException
      end

      assessments_xml = @assessments_xml_gateway.fetch(assessment_id)

      xml = assessment_xml[:xml]
      schema_type = assessment_xml[:schema_type]

      result = ViewModel::RdSapWrapper.new(xml, schema_type).to_hash

      {
        type_of_assessment: result[:type_of_assessment],
        address: {
          line1: result[:address_line1],
          line2: result[:address_line2],
          line3: result[:address_line3],
          line4: result[:address_line4],
          town: result[:town],
          postcode: result[:postcode],
        },
        address_id: result[:address_id],
        country_code: result[:country_code],
        inspection_date: result[:date_of_assessment],
        lodgement_date: result[:date_of_registration],
      }
    end
  end
end
