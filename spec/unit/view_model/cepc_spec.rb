require_relative "xml_view_test_helper"

describe ViewModel::CepcWrapper do
  # You should only need to add to this list to test new CEPC schema
  supported_schema = [
    {
      schema_name: "CEPC-8.0.0",
      xml: Samples.xml("CEPC-8.0.0", "cepc"),
      unsupported_fields: [],
      different_fields: {},
    },
    {
      schema_name: "CEPC-NI-8.0.0",
      xml: Samples.xml("CEPC-NI-8.0.0", "cepc"),
      unsupported_fields: [],
      different_fields: {},
    },
    {
      schema_name: "CEPC-7.1",
      xml: Samples.xml("CEPC-7.1", "cepc"),
      unsupported_fields: [],
      different_fields: {
        address: {
          address_id: "000000000001",
          address_line1: "2 Lonely Street",
          address_line2: nil,
          address_line3: nil,
          address_line4: nil,
          town: "Post-Town1",
          postcode: "A0 0AA",
        },
      },
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

  it "should read the appropriate values from the XML doc" do
    test_xml_doc(supported_schema, asserted_keys)
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::CepcWrapper.new "", "invalid"
    }.to raise_error.with_message "Unsupported schema type"
  end
end
