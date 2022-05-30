describe Helper::AddressSearchHelper do
  describe "#postcode_and_number_expression" do
    it "returns a string of a sql expression for filtering by postcode and building number" do
      expect(described_class.postcode_and_number_expression).to be_a(String)
      expect(described_class.postcode_and_number_expression.to_s.strip).to start_with("AND
        a.postcode ")
    end
  end

  describe "#clean_building_identifier" do
    it "returns a string of a with special chars removed", aggregate_failures: true do
      expect(described_class.clean_building_identifier("1")).to eq("1")
      expect(described_class.clean_building_identifier("1() Some Street")).to eq("1 Some Street")
      expect(described_class.clean_building_identifier("1: Some Street")).to eq("1 Some Street")
    end
  end
end
