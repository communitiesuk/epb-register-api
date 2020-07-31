describe ViewModel::Cepc::CepcWrapper do
  # You should only need to add to this list to test new CEPC schema
  supported_schema = [
    {
      schema_name: "CEPC-8.0.0",
      xml_file: "spec/fixtures/samples/cepc.xml",
      unsupported_fields: [],
    },
  ].freeze

  # You should only need to add to this list to test new fields on all CEPC schema
  asserted_keys = {
    assessment_id: "0000-0000-0000-0000-0000",
    date_of_expiry: "2026-05-04",
    address: {
      address_id: "UPRN-000000000001",
      address_line1: "2 Lonely Street",
      address_line2: nil,
      address_line3: nil,
      address_line4: nil,
      town: "Post-Town1",
      postcode: "A0 0AA",
    },
    technical_information: {
      main_heating_fuel: "Natural Gas",
      building_environment: "Air Conditioning",
      floor_area: "403",
      building_level: "3",
    },
    building_emission_rate: "67.09",
    primary_energy_use: "413.22",
    related_rrn: "4192-1535-8427-8844-6702",
    new_build_rating: "28",
    new_build_band: "b",
    existing_build_rating: "81",
    existing_build_band: "d",
    energy_efficiency_rating: "80",
    assessor: {
      scheme_assessor_id: "SPEC000000",
      name: "TEST NAME BOI",
      company_details: {
        name: "Joe Bloggs Ltd", address: "123 My Street, My City, AB3 4CD"
      },
      contact_details: { email: "test@testscheme.com", telephone: "012345" },
    },
    report_type: "3",
    type_of_assessment: "CEPC",
    current_energy_efficiency_band: "d",
    date_of_assessment: "2020-05-04",
    date_of_registration: "2020-05-04",
    related_party_disclosure: "1",
    property_type: "B1 Offices and Workshop businesses",
  }.freeze

  it "should read the appropriate value from the XML doc" do
    supported_schema.each do |schema|
      xml_file = File.read File.join Dir.pwd, schema[:xml_file]
      cepc =
        ViewModel::Cepc::CepcWrapper.new(xml_file, schema[:schema_name]).to_hash

      asserted_keys.each do |key, value|
        result = cepc[key]
        if schema[:unsupported_fields].include? key
          expect(result).to be_nil,
                            "Failed on #{schema[:schema_name]}:#{key}\n" \
                              "Unsupported fields must return nil, got \"#{result}\""
        else
          expect(result).to eq(value),
                            "Failed on #{schema[:schema_name]}:#{key}\n" \
                              "EXPECTED: \"#{value}\"\n" \
                              "     GOT: \"#{result}\"\n"
        end
      end
    end
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::Cepc::CepcWrapper.new "", "invalid"
    }.to raise_error.with_message "Unsupported schema type"
  end
end
