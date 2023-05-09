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
      expiry_date: Time.new(2030, 5, 3).to_date,
      current_band: "e",
      property_type: "Mid-floor flat",
      built_form: "End-Terrace",
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
      expiry_date: "2030-05-03",
      current_band: "e",
      property_type: "Mid-floor flat",
      built_form: "End-Terrace",
    }
  end

  let(:domain) { described_class.new(**arguments) }

  describe "#to_hash" do
    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_data
    end
  end
end
