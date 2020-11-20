require_relative "xml_view_test_helper"

describe ViewModel::AcCertWrapper do
  context "Testing the AC-CERT schemas" do
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "ac-cert"),
        unsupported_fields: [],
        different_fields: { related_rrn: nil },
      },
      {
        schema_name: "CEPC-NI-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "ac-cert"),
        unsupported_fields: [],
        different_fields: { related_rrn: nil },
      },
      {
        schema_name: "CEPC-7.1",
        xml: Samples.xml("CEPC-7.1", "ac-cert"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-7.0",
        xml: Samples.xml("CEPC-7.0", "ac-cert"),
        unsupported_fields: [],
        different_fields: {},
      },
    ].freeze

    asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      report_type: "6",
      type_of_assessment: "AC-CERT",
      date_of_expiry: "2024-05-04",
      date_of_registration: "2020-05-20",
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
        refrigerant_charge: "50",
      },
      related_rrn: "0000-0000-0000-0000-0001",
      subsystems: [
        {
          number: "VOL001/SYS001 R410A Inverter Split Systems to Sales Area",
          description:
            "This sub system comprised of; 4Nr 10kW R410A Mitsubishi Heavy Industries inverter driven split AC condensers interconnected to indoor cassette units within the Sales Area dating from circa 2014.",
          age: "2014",
          refrigerantType: "R410A",
        },
      ],
      assessor: {
        scheme_assessor_id: "SPEC000000",
        name: "Test Assessor Name",
        contact_details: {
          email: "test@example.com", telephone: "07555 666777"
        },
        company_details: {
          name: "Assess Energy Limited",
          address: "111 Twotwotwo Street, Mytown,, MT7 1AA",
        },
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
