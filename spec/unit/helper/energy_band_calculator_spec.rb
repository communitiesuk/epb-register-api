require "rspec"

describe "Helper::EnergyBandCalculator" do
  context "when calculating energy band for domestic property" do
    it "returns a band of G for a rating of 17" do
      expect(Helper::EnergyBandCalculator.domestic(17)).to eq "g"
    end
  end

  context "when calculating energy band for commercial property" do
    it "returns a band of A+ for a rating of -1" do
      expect(Helper::EnergyBandCalculator.commercial(-1)).to eq "a+"
    end
  end
end
