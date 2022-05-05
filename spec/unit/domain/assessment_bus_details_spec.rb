describe Domain::AssessmentBusDetails do
  let(:rrn) { "0123-4567-8901-2345-6789" }

  let(:arguments) do
    {
      epc_rrn: rrn,
      report_type: "RdSAP",
      expiry_date: Time.new(2030, 5, 3).to_date,
      cavity_wall_insulation_recommended: true,
      loft_insulation_recommended: false,
      secondary_heating: "Electric bar heater",
      address: {
        address_id: "UPRN-000000000123",
        address_line_1: "22 Acacia Avenue",
        address_line_2: "",
        address_line_3: "",
        address_line_4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
      },
      dwelling_type: "Top-floor flat",
    }
  end

  let(:expected_data) do
    {
      epc_rrn: rrn,
      report_type: "RdSAP",
      expiry_date: "2030-05-03",
      cavity_wall_insulation_recommended: true,
      loft_insulation_recommended: false,
      secondary_heating: "Electric bar heater",
      address: {
        address_id: "UPRN-000000000123",
        address_line_1: "22 Acacia Avenue",
        address_line_2: "",
        address_line_3: "",
        address_line_4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
      },
      dwelling_type: "Top-floor flat",
    }
  end

  let(:domain) { described_class.new arguments }

  describe "#to_hash" do
    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_data
    end
  end

  describe "#rrn" do
    it "returns the RRN" do
      expect(domain.rrn).to eq rrn
    end
  end
end
