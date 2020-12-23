require_relative "xml_view_test_helper"




describe ViewModel::CepcWrapper do

  # You should only need to add to this list to test new CEPC schema
  supported_schema = set_supported_schema

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
      contact_details: { email: "a@b.c", telephone: "012345" },
    },
    report_type: "3",
    type_of_assessment: "CEPC",
    current_energy_efficiency_band: "d",
    date_of_assessment: "2020-05-04",
    date_of_registration: "2020-05-04",
    related_party_disclosure: "1",
    property_type: "B1 Offices and Workshop businesses",
  }.freeze



  it "should read the appropriate values from the XML doc against the to hash method " do
    test_xml_doc(supported_schema, asserted_keys)
  end

  it "should read the appropriate values from the XML doc against the to report method " do
    hash_to_test = {
      rrn: "0000-0000-0000-0000-0000",
      address1: "2 Lonely Street",
      address2: nil,
      address3: nil,
      address4: nil,
      posttown: "Post-Town1",
      postcode: "A0 0AA",
      building_reference_number: "UPRN-000000000001",
      asset_rating: "80",
      asset_rating_band: "d",
      property_type: "B1 Offices and Workshop businesses",
      inspection_date: "2020-05-04",
      lodgement_date: "2020-05-04",
      transaction_type: "1",
      new_build_benchmark: "28",
      existing_stock_benchmark: "81",
      standard_emissions: "42.07",
      building_emissions: "67.09",
      main_heating_fuel: "Natural Gas",
      building_level: "3",
      floor_area: "403",
      other_fuel_description: "Test",
      special_energy_uses: "Test sp",
      aircon_present: "N",
      aircon_kw_rating: "100",
      estimated_aircon_kw_rating: "3",
      ac_inpsection_commissioned: "1",
      target_emissions: "23.2",
      typical_emissions: "67.98",
      building_environment: "Air Conditioning",
      primary_energy: "413.22",
      report_type: "3",
    }

    update_schema_for_report(supported_schema)

    test_xml_doc(supported_schema, hash_to_test, true)
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::CepcWrapper.new "", "invalid"
    }.to raise_error.with_message "Unsupported schema type"
  end
end
