describe Domain::AssessmentForPrsDatabaseDetails do
  let(:gateway_response_rrn) do
    {
      "address_line1" => "1 Some Street",
      "address_line2" => "",
      "address_line3" => "",
      "address_line4" => "",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0000-0000-0000-0000-0000",
      "expiry_date" => "2030-05-03 00:00:00.000000000 +0000",
      "latest_epc_rrn_for_address" => "0000-0000-0000-0000-0002",
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "type_of_assessment" => "RdSAP",
    }
  end

  let(:gateway_response_uprn) do
    {
      "address_line1" => "1 Some Street",
      "address_line2" => "",
      "address_line3" => "",
      "address_line4" => "",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0123-4567-8901-2345-6789",
      "expiry_date" => "2035-05-03 00:00:00.000000000 +0000",
      "rn" => 1,
      "type_of_assessment" => "RdSAP",
      "latest_epc_rrn_for_address" => "0123-4567-8901-2345-6789",
    }
  end

  let(:gateway_response_with_nil) do
    {
      "address_line1" => "1 Some Street",
      "address_line2" => nil,
      "address_line3" => nil,
      "address_line4" => nil,
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0123-4567-8901-2345-6789",
      "expiry_date" => "2035-05-03 00:00:00.000000000 +0000",
      "rn" => 1,
      "type_of_assessment" => "RdSAP",
      "latest_epc_rrn_for_address" => "0123-4567-8901-2345-6789",
    }
  end

  let(:expected_domain_response_rrn) do
    {
      address: {
        address_line1: "1 Some Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Whitbury",
        postcode: "SW1A 2AA",
      },
      current_energy_efficiency_rating: 50,
      epc_rrn: "0000-0000-0000-0000-0000",
      expiry_date: "2030-05-03 00:00:00.000000000 +0000",
      latest_epc_rrn_for_address: "0000-0000-0000-0000-0002",
      current_energy_efficiency_band: "e",
    }
  end

  let(:expected_domain_response_uprn) do
    {
      address: {
        address_line1: "1 Some Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Whitbury",
        postcode: "SW1A 2AA",
      },
      current_energy_efficiency_rating: 50,
      epc_rrn: "0123-4567-8901-2345-6789",
      expiry_date: "2035-05-03 00:00:00.000000000 +0000",
      latest_epc_rrn_for_address: "0123-4567-8901-2345-6789",
      current_energy_efficiency_band: "e",
    }
  end

  context "when the details provided are from search by rrn" do
    let(:domain) { described_class.new(gateway_response: gateway_response_rrn) }

    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_domain_response_rrn
    end
  end

  context "when the details provided are from search by uprn" do
    let(:domain) { described_class.new(gateway_response: gateway_response_uprn) }

    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_domain_response_uprn
    end
  end

  context "when the details provided include nil in the address" do
    let(:domain) { described_class.new(gateway_response: gateway_response_with_nil) }

    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_domain_response_uprn
    end
  end
end
