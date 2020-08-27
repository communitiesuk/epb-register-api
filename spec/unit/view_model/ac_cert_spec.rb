require_relative "xml_view_test_helper"

describe ViewModel::AcCertWrapper do
  context "Testing the AC-CERT schemas" do
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "ac-cert"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-NI-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "ac-cert"),
        unsupported_fields: [],
        different_fields: {},
      },
    ].freeze

    asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      report_type: "6",
      type_of_assessment: "AC-CERT",
      date_of_expiry: "2024-05-04",
      address: {
        address_line1: "2 Lonely Street",
        address_line2: nil,
        address_line3: nil,
        address_line4: nil,
        town: "Post-Town1",
        postcode: "A0 0AA",
      },
      technical_information: {
        date_of_assessment: "2020-05-20",
        building_complexity: "Level 3",
        calculation_tool: "Sterling Accreditation, Sterling e-Volve, v1.2",
        f_gas_compliant_date: "00/00/,,00",
        ac_rated_output: "40",
        random_sampling: "Y",
        treated_floor_area: "1876",
        ac_system_metered: "0",
      },
    }.freeze

    it "should read the appropriate values from the XML doc" do
      test_xml_doc(supported_schema, asserted_keys)
    end

    it "returns the expect error without a valid schema type" do
      expect {
        ViewModel::AcCertWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
