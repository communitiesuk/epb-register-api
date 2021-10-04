describe Helper::ValidatePostcodeHelper do
  describe ".format_postcode" do
    it "adds a space and capitalises the postcode" do
      expect(described_class.format_postcode("sw1A2aa")).to eq("SW1A 2AA")
    end
  end

  describe ".valid_postcode?" do
    it "returns true for a valid, formatted postcode" do
      expect(described_class.valid_postcode?("SW1A 2AA")).to eq(true)
    end

    it "returns true for a valid, unformatted postcode" do
      expect(described_class.valid_postcode?("sw1A2aa")).to eq(true)
    end

    it "returns false if the postcode is shorter than 4 characters" do
      expect(described_class.valid_postcode?("sw1")).to eq(false)
    end
  end
end
