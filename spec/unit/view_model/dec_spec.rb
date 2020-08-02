require_relative "xml_view_test_helper"

describe ViewModel::Dec::DecWrapper do
  # You should only need to add to this list to test new CEPC schema
  supported_schema = [
      {
          schema_name: "CEPC-8.0.0",
          xml_file: "spec/fixtures/samples/dec.xml",
          unsupported_fields: [],
      },
  ].freeze

  # You should only need to add to this list to test new fields on all CEPC schema
  asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      date_of_expiry: "2026-05-04",
      energy_efficiency_rating: "1",
      energy_efficiency_band: "a",
      address: {
          address_id: "UPRN-000000000001",
          address_line1: "2 Lonely Street",
          address_line2: nil,
          address_line3: nil,
          address_line4: nil,
          town: "Post-Town1",
          postcode: "A0 0AA",
      },
      type_of_assessment: "DEC",
      report_type: "1"
  }.freeze

  it "should read the appropriate values from the XML doc" do
    test_xml_doc(supported_schema, asserted_keys)
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::Dec::DecWrapper.new "", "invalid"
    }.to raise_error.with_message "Unsupported schema type"
  end
end
