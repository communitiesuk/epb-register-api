describe Helper::EnergyBandCalculator do
  it "returns a band of G for a rating of 17" do
    expect(described_class.domestic(17)).to eq("g")
  end

  it "returns a band of A+ for a rating of -1" do
    expect(described_class.commercial(-1)).to eq("a+")
  end

  it "returns a band of A for a rating of " do
    expect(described_class.commercial(0)).to eq("a")
  end
end
