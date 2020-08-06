require_relative "xml_view_test_helper"

describe ViewModel::DecRrWrapper do
  context "Testing the DEC-RR schemas" do
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml_file: "spec/fixtures/samples/dec-rr.xml",
        unsupported_fields: [],
      },
    ].freeze

    asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      report_type: "2",
      type_of_assessment: "DEC-RR",
      date_of_expiry: "2028-05-03",
      address: {
        address_line1: "1 Lonely Street",
        address_line2: nil,
        address_line3: nil,
        address_line4: nil,
        town: "Post-Town0",
        postcode: "A0 0AA",
      },
    }.freeze

    it "should read the appropriate values from the XML doc" do
      test_xml_doc(supported_schema, asserted_keys)
    end

    it "returns the expect error without a valid schema type" do
      expect {
        ViewModel::DecRrWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
