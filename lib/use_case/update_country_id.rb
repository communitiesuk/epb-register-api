module UseCase
  class UpdateCountryId
    def initialize(assessments_gateway:, country_use_case:, add_country_id_from_address:, assessments_country_id_gateway:)
      @assessments_gateway = assessments_gateway
      @country_use_case = country_use_case
      @add_country_id_from_address = add_country_id_from_address
      @assessments_country_id_gateway = assessments_country_id_gateway
    end

    def execute(assessments_ids:)
      assessments_ids_array = assessments_ids.gsub(/[[:space:]]/, "").split(",")
      assessments_ids_array.each do |assessment_id|
        assessment_location = @assessments_gateway.fetch_location_by_assessment_id(assessment_id)
        postcode = assessment_location["postcode"]
        address_id = assessment_location["address_id"]
        xml = assessment_location["xml"]
        schema_type = assessment_location["schema_type"]
        country_lookup = @country_use_case.execute(rrn: assessment_id, postcode:, address_id:)
        begin
          lodgement_domain = Domain::Lodgement.new(xml, schema_type)
        rescue NoMethodError => e
          puts "rrn: #{assessment_id} for #{e.message}"
          next
        end
        @add_country_id_from_address.execute(country_domain: country_lookup, lodgement_domain:)
        country_id = lodgement_domain.fetch_country_id
        @assessments_country_id_gateway.insert(assessment_id:, country_id:, upsert: true)
      end
    end
  end
end
