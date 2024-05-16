module UseCase
  class BackfillCountryId
    def initialize(assessment_ids_use_case:, assessments_gateway:, assessments_xml_gateway:, country_use_case:, add_country_id_from_address:)
      @assessment_ids_use_case = assessment_ids_use_case
      @assessments_gateway = assessments_gateway
      @assessments_xml_gateway = assessments_xml_gateway
      @country_use_case = country_use_case
      @add_country_id_from_address = add_country_id_from_address
    end

    def execute(date_from:, date_to:, assessment_types: nil)
      assessments_ids = @assessment_ids_use_case.execute(date_from:, date_to:, assessment_types:)

      assessments_ids.each do |assessment_id|
        assessment_location = @assessments_gateway.fetch_location_by_assessment_id(assessment_id)
        assessment_data = @assessments_xml_gateway.fetch(assessment_id)

        postcode = assessment_location["postcode"]
        address_id = assessment_location["address_id"]
        xml = assessment_data[:xml]
        schema_type = assessment_data[:schema_type]

        country_lookup = @country_use_case.execute(rrn: assessment_id, postcode:, address_id:)
        lodgement_domain = Domain::Lodgement.new(xml, schema_type)

        @add_country_id_from_address.execute(country_domain: country_lookup, lodgement_domain:)
        country_id = lodgement_domain.fetch_country_id
        @assessments_gateway.update_field(assessment_id, "country_id", country_id)
      end
    end
  end
end
