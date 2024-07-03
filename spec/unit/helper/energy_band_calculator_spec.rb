describe Helper::EnergyBandCalculator do
  context "when calculating energy band for domestic property" do
    it "returns a band of G for a rating of 17" do
      expect(described_class.domestic(17)).to eq("g")
    end

    it "returns nil for a nil rating" do
      expect(described_class.domestic(nil)).to be_nil
    end
  end

  context "when calculating energy band for non-domestic property" do
    it "returns a band of A+ for a rating of -1" do
      expect(described_class.commercial(-1)).to eq("a+")
    end

    it "returns a band of A for a rating of" do
      expect(described_class.commercial(0)).to eq("a")
    end

    it "returns nil for a nil rating" do
      expect(described_class.commercial(nil)).to be_nil
    end
  end
end
