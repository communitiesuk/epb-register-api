require_relative "xml_view_test_helper"

describe ViewModel::DecSummaryWrapper do
  # You should only need to add to this list to test new CEPC schema
  supported_schema = [
    { schema_name: "CEPC-8.0.0", xml: Samples.xml("CEPC-8.0.0", "dec") },
    { schema_name: "CEPC-NI-8.0.0", xml: Samples.xml("CEPC-NI-8.0.0", "dec") },
    {
      schema_name: "CEPC-7.1",
      xml: Samples.xml("CEPC-7.1", "dec"),
      replace: {
        "UPRN-000000000001": "",
      },
    },
    {
      schema_name: "CEPC-7.0",
      xml: Samples.xml("CEPC-7.0", "dec"),
      replace: {
        "UPRN-000000000001": "",
      },
    },
    {
      schema_name: "CEPC-6.0",
      xml: Samples.xml("CEPC-6.0", "dec"),
      replace: {
        "UPRN-000000000001": "",
      },
    },
  ].freeze

  let(:sample_response) { Samples.xml("CEPC-8.0.0", "dec_summary") }

  supported_schema.each do |schema|
    it "can produce the correct DEC summary for " + schema[:schema_name] do
      shortened_dec_summary_xml =
        described_class.new(schema[:xml], schema[:schema_name]).to_xml

      expected_response = sample_response
      if schema.key?(:replace)
        schema[:replace].each do |from, to|
          expected_response.gsub!(from.to_s, to)
        end
      end

      expect(shortened_dec_summary_xml).to eq(expected_response)
    end
  end
end
