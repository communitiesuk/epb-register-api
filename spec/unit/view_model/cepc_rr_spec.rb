describe ViewModel::CepcRr::CepcRrWrapper do
  context "Testing the CEPC-RR schemas" do
    # You should only need to add to this list to test new CEPC schema
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml_file: "spec/fixtures/samples/cepc-rr.xml",
        unsupported_fields: [],
      },
    ].freeze

    # You should only need to add to this list to test new fields on all CEPC schema
    asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      report_type: "4",
      type_of_assessment: "CEPC-RR",
      date_of_expiry: "2021-05-03",
      address: {
          address_id: "UPRN-000000000000",
          address_line1: "1 Lonely Street",
          address_line2: nil,
          address_line3: nil,
          address_line4: nil,
          town: "Post-Town0",
          postcode: "A0 0AA",
      },
    }.freeze

    it "should read the appropriate value from the XML doc" do
      supported_schema.each do |schema|
        xml_file = File.read File.join Dir.pwd, schema[:xml_file]
        cepc_rr =
          ViewModel::CepcRr::CepcRrWrapper.new(xml_file, schema[:schema_name])
            .to_hash

        asserted_keys.each do |key, value|
          result = cepc_rr[key]
          if schema[:unsupported_fields].include? key
            expect(result).to be_nil,
                              "Failed on #{schema[:schema_name]}:#{key}\n" \
                                "Unsupported fields must return nil, got \"#{result}\""
          else
            expect(result).to eq(value),
                              "Failed on #{schema[:schema_name]}:#{key}\n" \
                                "EXPECTED: \"#{value}\"\n" \
                                "     GOT: \"#{result}\"\n"
          end
        end
      end
    end

    it "returns the expect error without a valid schema type" do
      expect {
        ViewModel::CepcRr::CepcRrWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
