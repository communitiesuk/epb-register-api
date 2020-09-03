require_relative "xml_view_test_helper"

describe ViewModel::CepcRrWrapper do
  context "Testing the CEPC-RR schemas" do
    # You should only need to add to this list to test new CEPC schema
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-NI-8.0.0",
        xml: Samples.xml("CEPC-NI-8.0.0", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-7.1",
        xml: Samples.xml("CEPC-7.1", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {
          address: {
            address_id: "000000000000",
            address_line1: "1 Lonely Street",
            address_line2: nil,
            address_line3: nil,
            address_line4: nil,
            town: "Post-Town0",
            postcode: "A0 0AA",
          },
        },
      },
      {
        schema_name: "CEPC-7.0",
        xml: Samples.xml("CEPC-7.0", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {
          address: {
            address_id: "000000000000",
            address_line1: "1 Lonely Street",
            address_line2: nil,
            address_line3: nil,
            address_line4: nil,
            town: "Post-Town0",
            postcode: "A0 0AA",
          },
        },
      },
    ].freeze

    # You should only need to add to this list to test new fields on all CEPC schema
    asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      report_type: "4",
      type_of_assessment: "CEPC-RR",
      date_of_expiry: "2021-05-03",
      date_of_registration: "2020-05-05",
      related_certificate: "0000-0000-0000-0000-0001",
      address: {
        address_id: "UPRN-000000000000",
        address_line1: "1 Lonely Street",
        address_line2: nil,
        address_line3: nil,
        address_line4: nil,
        town: "Post-Town0",
        postcode: "A0 0AA",
      },
      assessor: {
        scheme_assessor_id: "SPEC000000",
        name: "Mrs Report Writer",
        company_details: {
          name: "Joe Bloggs Ltd", address: "123 My Street, My City, AB3 4CD"
        },
        contact_details: { email: "a@b.c", telephone: "012345" },
      },
      short_payback_recommendations: [
        {
          code: "1",
          text: "Consider replacing T8 lamps with retrofit T5 conversion kit.",
          cO2Impact: "HIGH",
        },
        {
          code: "3",
          text:
            "Introduce HF (high frequency) ballasts for fluorescent tubes: Reduced number of fittings required.",
          cO2Impact: "LOW",
        },
      ],
      medium_payback_recommendations: [
        {
          code: "2",
          text: "Add optimum start/stop to the heating system.",
          cO2Impact: "MEDIUM",
        },
      ],
      long_payback_recommendations: [
        {
          code: "3",
          text: "Consider installing an air source heat pump.",
          cO2Impact: "HIGH",
        },
      ],
      other_recommendations: [
        { code: "4", text: "Consider installing PV.", cO2Impact: "HIGH" },
      ],
      technical_information: {
        floor_area: "10",
        building_environment: "Natural Ventilation Only",
        calculation_tool: "Calculation-Tool0",
      },
      related_party_disclosure: "Related to the owner",
    }.freeze

    it "should read the appropriate values from the XML doc" do
      test_xml_doc(supported_schema, asserted_keys)
    end

    it "returns the expect error without a valid schema type" do
      expect {
        ViewModel::CepcRrWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
