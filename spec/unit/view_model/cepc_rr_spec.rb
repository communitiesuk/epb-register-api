require_relative "xml_view_test_helper"

describe ViewModel::CepcRrWrapper do
  context "Testing the CEPC-RR schemas" do
    # You should only need to add to this list to test new CEPC schema
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "cepc-rr"),
        unsupported_fields: [],
        different_fields: { related_certificate: nil },
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
        different_fields: {},
        different_buried_fields: {
          address: { address_id: "LPRN-000000000000" },
        },
      },
      {
        schema_name: "CEPC-7.0",
        xml: Samples.xml("CEPC-7.0", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: { address_id: "LPRN-000000000000" },
        },
      },
      {
        schema_name: "CEPC-6.0",
        xml: Samples.xml("CEPC-6.0", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: { address_id: "LPRN-000000000000" },
        },
      },
      {
        schema_name: "CEPC-5.1",
        xml: Samples.xml("CEPC-5.1", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: { address_id: "LPRN-000000000000" },
        },
      },
      {
        schema_name: "CEPC-5.0",
        xml: Samples.xml("CEPC-5.0", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: { address_id: "LPRN-000000000000" },
        },
      },
      {
        schema_name: "CEPC-4.0",
        xml: Samples.xml("CEPC-4.0", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: { address_id: "LPRN-000000000000" },
          technical_information: { building_environment: "Air Conditioning" },
        },
      },
      {
        schema_name: "CEPC-3.1",
        xml: Samples.xml("CEPC-3.1", "cepc-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: { address_id: "LPRN-000000000000" },
          technical_information: { building_environment: "Air Conditioning" },
        },
      },
    ].freeze

    # use hash from sample
    it "should read the appropriate values from the XML doc using the to hash method" do
      test_xml_doc(supported_schema, Samples::ViewModels::CepRr.asserted_hash)
    end

    it "should read the appropriate values from the XML doc using the to report method" do

      test_xml_doc(supported_schema, Samples::ViewModels::CepRr.report_test_hash, true)
    end

    it "returns the expect error without a valid schema type" do
      expect {
        ViewModel::CepcRrWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
