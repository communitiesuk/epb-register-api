require_relative "xml_view_test_helper"

describe ViewModel::AcReportWrapper do
  context "Testing the AC-REPORT schemas" do
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-NI-8.0.0",
        xml: Samples.xml("CEPC-NI-8.0.0", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-7.1",
        xml: Samples.xml("CEPC-7.1", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-7.0",
        xml: Samples.xml("CEPC-7.1", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
      },
    ].freeze

    asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      report_type: "5",
      type_of_assessment: "AC-REPORT",
      date_of_expiry: "2030-05-04",
      address: {
        address_line1: "2 Lonely Street",
        address_line2: nil,
        address_line3: nil,
        address_line4: nil,
        town: "Post-Town1",
        postcode: "A0 0AA",
      },
      related_party_disclosure: "1",
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
        ViewModel::AcReportWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
