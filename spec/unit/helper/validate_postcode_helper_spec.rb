describe Helper::ValidatePostcodeHelper do
  describe ".format_postcode" do
    it "adds a space and capitalises the postcode" do
      expect(described_class.format_postcode("sw1A2aa")).to eq("SW1A 2AA")
    end

    it "removes whitespace before the postcode" do
      expect(described_class.format_postcode(" SW1A 2AA")).to eq("SW1A 2AA")
    end

    it "removes whitespace after the postcode" do
      expect(described_class.format_postcode("SW1A 2AA ")).to eq("SW1A 2AA")
    end

    it "normalises whitespace within postcode" do
      expect(described_class.format_postcode(" SW1A   2AA ")).to eq("SW1A 2AA")
    end

    it "doesn't throw IndexError if stripped postcode is too short" do
      expect(described_class.format_postcode("  k  k  ")).to eq("KK")
    end
  end

  describe ".valid_postcode?" do
    it "returns true for a valid, formatted postcode" do
      expect(described_class.valid_postcode?("SW1A 2AA")).to be(true)
    end

    it "returns true for a valid, unformatted postcode" do
      expect(described_class.valid_postcode?("sw1A2aa")).to be(true)
    end

    it "returns false if the postcode is shorter than 4 characters" do
      expect(described_class.valid_postcode?("sw1")).to be(false)
    end
  end
end
