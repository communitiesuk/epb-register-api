require_relative "xml_view_test_helper"

describe ViewModel::RdSapWrapper do
  # You should only need to add to this list to test new CEPC schema
  supported_schema = [
    {
      schema_name: "RdSAP-Schema-20.0.0",
      xml_file: "spec/fixtures/samples/rdsap.xml",
      unsupported_fields: [],
    },
    {
      schema_name: "RdSAP-Schema-NI-20.0.0",
      xml_file: "spec/fixtures/samples/rdsap-ni.xml",
      unsupported_fields: [],
    },
  ].freeze

  # You should only need to add to this list to test new fields on all CEPC schema
  asserted_keys = { type_of_assessment: "RdSAP" }.freeze

  it "should read the appropriate values from the XML doc" do
    test_xml_doc(supported_schema, asserted_keys)
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::RdSapWrapper.new "", "invalid"
    }.to raise_error.with_message "Unsupported schema type"
  end
end
