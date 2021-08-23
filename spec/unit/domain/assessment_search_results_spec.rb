describe Domain::AssessmentSearchResult do
  let(:arguments) do
    {
      type_of_assessment: "RdSAP",
      assessment_id: "0000-0000-0000-0000-0000",
      current_energy_efficiency_rating: 50,
      opt_out: false,
      postcode: "A0 0AA",
      date_of_expiry: Time.new(2030, 5, 3).to_date,
      date_registered: Time.new(2020, 5, 4).to_date,
      address_id: "UPRN-000000000123",
      address_line1: "1 Some Street",
      address_line2: "",
      address_line3: "",
      address_line4: "",
      town: "Whitbury",
      date_of_assessment: Time.new(2020, 5, 4).to_date,
    }
  end

  let(:expected_data) do
    {
      address_id: "UPRN-000000000123",
      address_line1: "1 Some Street",
      address_line2: "",
      address_line3: "",
      address_line4: "",
      assessment_id: "0000-0000-0000-0000-0000",
      current_energy_efficiency_band: "e",
      current_energy_efficiency_rating: 50,
      date_of_assessment: "2020-05-04",
      date_of_expiry: "2030-05-03",
      date_of_registration: "2020-05-04",
      opt_out: false,
      postcode: "A0 0AA",
      status: "ENTERED",
      town: "Whitbury",
      type_of_assessment: "RdSAP",
    }
  end

  describe ".to_hash" do
    let(:domain) { described_class.new(arguments) }

    it "returns the expected data" do
      expect(domain.to_hash).to eq(expected_data)
    end

    it "returns cancelled_at, not_for_issue_at, date_of_expiry in YYYY-MM-DD format" do
      expect(domain.to_hash[:date_of_expiry]).to eq("2030-05-03")
    end

    it "returns current energy efficiency band" do
      expect(domain.to_hash[:current_energy_efficiency_band]).to eq("e")
    end
  end
end
