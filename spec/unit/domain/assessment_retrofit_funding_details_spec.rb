describe Domain::AssessmentRetrofitFundingDetails do
  let(:arguments) do
    {
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
      },
      uprn: "UPRN-000000000123",
      lodgement_date: "2020-05-04",
      current_band: "e",
    }
  end

  let(:expected_data) do
    {
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
      },
      uprn: "000000000123",
      lodgement_date: "2020-05-04",
      current_band: "e",
    }
  end

  let(:domain) { described_class.new(**arguments) }

  describe "#to_hash" do
    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_data
    end
  end
end
