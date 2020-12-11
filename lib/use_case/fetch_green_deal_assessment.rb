module UseCase
  class FetchGreenDealAssessment
    class NotFoundException < StandardError; end
    class AssessmentGone < StandardError; end
    class InvalidAssessmentTypeException < StandardError; end

    def initialize
      @assessments_gateway = Gateway::AssessmentsSearchGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
      @related_assessments_gateway = Gateway::RelatedAssessmentsGateway.new
      @search_address_by_address_id_use_case =
        UseCase::SearchAddressesByAddressId.new
      @assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
    end

    def execute(assessment_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format assessment_id
      assessment =
        @assessments_gateway.search_by_assessment_id(assessment_id, false).first

      raise NotFoundException unless assessment

      status = assessment.to_hash[:status]

      raise AssessmentGone if %w[CANCELLED NOT_FOR_ISSUE].include? status

      assessment_xml = @assessments_xml_gateway.fetch assessment_id
      xml = assessment_xml[:xml]
      schema_type = assessment_xml[:schema_type]

      type = assessment.to_hash[:type_of_assessment]

      raise InvalidAssessmentTypeException unless %w[RdSAP SAP].include? type

      result = ViewModel::Factory.new.create(xml, schema_type).get_view_model

      related_assessments =
        @related_assessments_gateway.by_address_id result.address_id
      related_assessment = related_assessments.first&.to_hash

      latest_assessment_flag = true
      unless related_assessment && related_assessment[:assessment_id] == assessment_id
        latest_assessment_flag = false
      end

      canonical_address = @assessments_address_id_gateway.fetch assessment_id

      source =
        if result.address_id.start_with? "UPRN"
          "GAZETEER"
        else
          "PREVIOUS_ASSESSMENT"
        end

      {
        type_of_assessment: type,
        address: {
          source: source,
          line1: result.address_line1,
          line2: result.address_line2,
          line3: result.address_line3,
          line4: result.address_line4,
          town: result.town,
          postcode: result.postcode,
        },
        address_id: result.address_id,
        address_identifiers: [
          canonical_address[:address_id],
          result.address_id,
        ].uniq,
        country_code: result.country_code,
        inspection_date: result.date_of_assessment,
        lodgement_date: result.date_of_registration,
        is_latest_assessment_for_address: latest_assessment_flag,
        status: status,
        main_fuel_type: result.main_fuel_type,
        secondary_fuel_type: result.secondary_fuel_type,
        water_heating_fuel: result.water_heating_fuel,
      }
    end
  end
end
