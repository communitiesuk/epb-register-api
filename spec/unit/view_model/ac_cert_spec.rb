require_relative "xml_view_test_helper"

describe ViewModel::AcCertWrapper do
  context "Testing the AC-CERT schemas" do
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml_file: "spec/fixtures/samples/ac-cert.xml",
        unsupported_fields: [],
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
