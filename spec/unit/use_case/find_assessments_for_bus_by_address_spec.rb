describe UseCase::FindAssessmentsForBusByAddress do
  subject(:use_case) { described_class.new(bus_gateway:, summary_use_case:) }

  let(:bus_gateway) { instance_double Gateway::BoilerUpgradeSchemeGateway }
  let(:summary_use_case) { instance_double UseCase::AssessmentSummary::Fetch }

  let(:rrn) { "0123-4567-8901-2345-6789" }
  let(:building_identifier) { "42" }
  let(:postcode) { "AB1 2CD" }

  let(:bus_details) do
    {
      "epc_rrn" => rrn,
      "report_type" => "RdSAP",
      "expiry_date" => Time.new(2030, 5, 3).to_date,
      "uprn" => "UPRN-000000000123",
    }
  end

  let(:assessment_summary) do
    {
      address: {
        address_line1: building_identifier,
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Anytown",
        postcode:,
      },
      current_energy_efficiency_band: "e",
      date_of_registration: "2020-05-04",
      date_of_expiry: Time.new(2030, 5, 3).to_date,
      superseded_by: nil,
      recommended_improvements: [
        { energy_performance_rating_improvement: 50,
          environmental_impact_rating_improvement: 50,
          green_deal_category_code: "1",
          improvement_category: "6",
          improvement_code: "5",
          improvement_description: nil,
          improvement_title: "",
          improvement_type: "A",
          indicative_cost: "£100 - £350",
          sequence: 1,
          typical_saving: "360",
          energy_performance_band_improvement: "e" },
        { energy_performance_rating_improvement: 60,
          environmental_impact_rating_improvement: 64,
          green_deal_category_code: "3",
          improvement_category: "2",
          improvement_code: "1",
          improvement_description: nil,
          improvement_title: "",
          improvement_type: "B",
          indicative_cost: "2000",
          sequence: 2,
          typical_saving: "99",
          energy_performance_band_improvement: "d" },
      ],
      type_of_assessment: "RdSAP",
      property_summary: [
        { energy_efficiency_rating: 1,
          environmental_efficiency_rating: 1,
          name: "wall",
          description: "Solid brick, as built, no insulation (assumed)" },
        { energy_efficiency_rating: 4,
          environmental_efficiency_rating: 4,
          name: "secondary_heating",
          description: "Electric bar heater" },
      ],
      dwelling_type: "Top-floor flat",
    }
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for address where one relevant assessment exists" do
    let(:expected_response) do
      Domain::AssessmentBusDetails.new(
        bus_details:,
        assessment_summary:,
      )
    end

    before do
      allow(bus_gateway).to receive(:search_by_postcode_and_building_identifier)
                              .with(postcode:, building_identifier:)
                              .and_return [bus_details]
      allow(summary_use_case).to receive(:execute).with(rrn).and_return assessment_summary
    end

    it "returns an assessment bus details object" do
      result = use_case.execute(postcode:, building_identifier:)
      expect(result).to be_a Domain::AssessmentBusDetails
      expect(result.to_hash).to eq expected_response.to_hash
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for address where multiple assessments can be found" do
    let(:rrn2) { "0000-0000-0000-0000-0001" }
    let(:reference_list) { Domain::AssessmentReferenceList.new(rrn, rrn2) }
    let(:bus_details2) do
      {
        "epc_rrn" => rrn2,
        "report_type" => "RdSAP",
        "expiry_date" => Time.new(2030, 5, 3).to_date,
        "uprn" => "UPRN-000000000124",
      }
    end

    before do
      allow(bus_gateway).to receive(:search_by_postcode_and_building_identifier)
                              .with(postcode:, building_identifier:)
                              .and_return [bus_details, bus_details2]
      allow(summary_use_case).to receive(:execute).with(rrn).and_return assessment_summary
      allow(summary_use_case).to receive(:execute).with(rrn2).and_return assessment_summary
    end

    it "returns the reference list object" do
      result = use_case.execute(postcode:, building_identifier:)
      expect(result).to be_a Domain::AssessmentReferenceList
      expect(result.references).to eq reference_list.references
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
