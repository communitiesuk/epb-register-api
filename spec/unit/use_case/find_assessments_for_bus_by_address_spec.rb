describe UseCase::FindAssessmentsForBusByAddress do
  subject(:use_case) { described_class.new(bus_gateway:) }

  let(:bus_gateway) { instance_double(Gateway::BoilerUpgradeSchemeGateway) }

  let(:building_identifier) { "42" }

  let(:postcode) { "AB1 2CD" }

  let(:existing_details) do
    Domain::AssessmentBusDetails.new(
      epc_rrn: "0123-4567-8901-2345-6789",
      report_type: "RdSAP",
      expiry_date: Time.new(2030, 5, 3).to_date,
      cavity_wall_insulation_recommended: true,
      loft_insulation_recommended: false,
      secondary_heating: "Electric bar heater",
      address: {
        address_id: "UPRN-000000000123",
        address_line_1: "#{building_identifier} Acacia Avenue",
        address_line_2: "",
        address_line_3: "",
        address_line_4: "",
        town: "Anytown",
        postcode:,
      },
      dwelling_type: "Top-floor flat",
    )
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for address where one relevant assessment exists" do
    before do
      allow(bus_gateway).to receive(:search_by_postcode_and_building_identifier)
                              .with(postcode:, building_identifier:)
                              .and_return(existing_details)
    end

    it "returns an assessment bus details object" do
      expect(use_case.execute(postcode:, building_identifier:)).to eq existing_details
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for address where two matching assessments can be found" do
    let(:reference_list) { Domain::AssessmentReferenceList.new("0000-0000-0000-0000-0001", "0000-0000-0000-1111-2222") }

    before do
      allow(bus_gateway).to receive(:search_by_postcode_and_building_identifier)
                              .with(postcode:, building_identifier:)
                              .and_return(reference_list)
    end

    it "returns the reference list object" do
      expect(use_case.execute(postcode:, building_identifier:)).to eq reference_list
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for address where there is no matching address" do
    before do
      allow(bus_gateway).to receive(:search_by_postcode_and_building_identifier)
                              .with(postcode:, building_identifier:)
                              .and_return(nil)
    end

    it "returns nil" do
      expect(use_case.execute(postcode:, building_identifier:)).to be_nil
    end
  end
end
