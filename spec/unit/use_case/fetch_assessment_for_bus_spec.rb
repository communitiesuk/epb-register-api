describe UseCase::FetchAssessmentForBus do
  subject(:use_case) { described_class.new(bus_gateway:) }

  let(:bus_gateway) { instance_double(Gateway::BoilerUpgradeSchemeGateway) }

  let(:rrn) { "0123-4567-8901-2345-6789" }

  let(:existing_details) do
    Domain::AssessmentBusDetails.new(
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
    )
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for an RRN that exists" do
    let(:rrn) { "0123-4567-8901-2345-6789" }

    let(:existing_details) do
      Domain::AssessmentBusDetails.new(
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
      )
    end

    before do
      allow(bus_gateway).to receive(:search_by_rrn).with(rrn).and_return existing_details
    end

    it "returns an assessment bus details object from the gateway" do
      expect(use_case.execute(rrn:)).to eq existing_details
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for an RRN that does not exist or is not applicable" do
    let(:rrn) { "0000-1111-2222-3333-4444" }

    before do
      allow(bus_gateway).to receive(:search_by_rrn).with(rrn).and_return nil
    end

    it "returns nil" do
      expect(use_case.execute(rrn:)).to be_nil
    end
  end
end
