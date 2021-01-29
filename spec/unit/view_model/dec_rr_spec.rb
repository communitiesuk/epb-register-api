require_relative "xml_view_test_helper"

describe ViewModel::DecRrWrapper do
  context "Testing the DEC-RR schemas" do
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "dec-rr"),
        unsupported_fields: [],
        different_fields: {
          related_rrn: nil,
        },
      },
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "dec-rr-large-building"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
        different_buried_fields: {
          technical_information: {
            floor_area: "8000",
          },
        },
      },
      {
        schema_name: "CEPC-NI-8.0.0",
        xml: Samples.xml("CEPC-NI-8.0.0", "dec-rr"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
      },
      {
        schema_name: "CEPC-7.1",
        xml: Samples.xml("CEPC-7.1", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
          },
        },
      },
      {
        schema_name: "CEPC-7.1",
        xml: Samples.xml("CEPC-7.1", "dec-rr-ni"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
            postcode: "BT0 0AA",
          },
        },
      },
      {
        schema_name: "CEPC-7.0",
        xml: Samples.xml("CEPC-7.0", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
          },
        },
      },
      {
        schema_name: "CEPC-7.0",
        xml: Samples.xml("CEPC-7.0", "dec-rr-ni"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
            postcode: "BT0 0AA",
          },
        },
      },
      {
        schema_name: "CEPC-6.0",
        xml: Samples.xml("CEPC-6.0", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
          },
        },
      },
      {
        schema_name: "CEPC-6.0",
        xml: Samples.xml("CEPC-6.0", "dec-rr-ni"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
            postcode: "BT0 0AA",
          },
        },
      },
      {
        schema_name: "CEPC-5.1",
        xml: Samples.xml("CEPC-5.1", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
          },
        },
      },
      {
        schema_name: "CEPC-5.1",
        xml: Samples.xml("CEPC-5.1", "dec-rr-ni"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
            postcode: "BT0 0AA",
          },
        },
      },
      {
        schema_name: "CEPC-5.0",
        xml: Samples.xml("CEPC-5.0", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
          },
        },
      },
      {
        schema_name: "CEPC-5.0",
        xml: Samples.xml("CEPC-5.0", "dec-rr-ni"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
            postcode: "BT0 0AA",
          },
        },
      },
      {
        schema_name: "CEPC-4.0",
        xml: Samples.xml("CEPC-4.0", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
          },
        },
      },
      {
        schema_name: "CEPC-4.0",
        xml: Samples.xml("CEPC-4.0", "dec-rr-ni"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
            postcode: "BT0 0AA",
          },
        },
      },
      {
        schema_name: "CEPC-3.1",
        xml: Samples.xml("CEPC-3.1", "dec-rr"),
        unsupported_fields: [],
        different_fields: {},
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
          },
        },
      },
      {
        schema_name: "CEPC-3.1",
        xml: Samples.xml("CEPC-3.1", "dec-rr-ni"),
        unsupported_fields: [],
        different_fields: {
          date_of_expiry: "2027-05-03",
        },
        different_buried_fields: {
          address: {
            address_id: "LPRN-000000000001",
            postcode: "BT0 0AA",
          },
        },
      },
    ].freeze

    asserted_keys = Samples::ViewModels::DecRr.asserted_hash

    it "should read the appropriate values from the XML doc  using the to hash method" do
      test_xml_doc(supported_schema, asserted_keys)
    end

    it "should read the appropriate values from the XML doc  using the to report method" do
      test_xml_doc(
        supported_schema,
        Samples::ViewModels::DecRr.report_test_hash,
        true,
      )
    end

    it "returns the expect error without a valid schema type" do
      expect {
        ViewModel::DecRrWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
