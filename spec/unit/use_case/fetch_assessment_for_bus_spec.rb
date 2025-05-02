describe UseCase::FetchAssessmentForBus do
  subject(:use_case) { described_class.new(bus_gateway:, summary_use_case:, domestic_digest_gateway:) }

  let(:bus_gateway) { instance_double(Gateway::BoilerUpgradeSchemeGateway) }
  let(:summary_use_case) { instance_double UseCase::AssessmentSummary::Fetch }
  let(:domestic_digest_gateway) { instance_double Gateway::DomesticDigestGateway }

  let(:rrn) { "0000-1111-2222-3333-4444" }
  let(:xml) { Samples.xml "RdSAP-Schema-20.0.0" }

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
        address_line1: "22 Acacia Avenue",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
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

  let(:domestic_digest) do
    { "main_fuel_type": "mains gas (not community)", "lzc_energy_sources": [1] }
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for an RRN that exists" do
    let(:expected_response) do
      Domain::AssessmentBusDetails.new(
        bus_details:,
        assessment_summary:,
        domestic_digest:,
      )
    end

    before do
      allow(bus_gateway).to receive(:search_by_rrn).with(rrn).and_return bus_details
      allow(summary_use_case).to receive(:execute).with(rrn).and_return assessment_summary
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "RdSAP-Schema-20.0.0",
      })
    end

    it "returns an assessment bus details object" do
      result = use_case.execute(rrn:)
      expect(result).to be_a Domain::AssessmentBusDetails
      expect(result.to_hash).to eq expected_response.to_hash
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details with an RRN for a CEPC" do
    let(:expected_response) do
      Domain::AssessmentBusDetails.new(
        bus_details:,
        assessment_summary:,
        domestic_digest:,
      )
    end

    before do
      bus_details["report_type"] = "CEPC"
      allow(bus_gateway).to receive(:search_by_rrn).with(rrn).and_return bus_details
      allow(summary_use_case).to receive(:execute).with(rrn).and_return assessment_summary
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn)
    end

    it "does not call the domestic digest gateway" do
      use_case.execute(rrn:)
      expect(domestic_digest_gateway).not_to have_received(:fetch_by_rrn)
    end

    it "returns nil for main_fuel_type" do
      result = use_case.execute(rrn:)
      expect(result.to_hash[:main_fuel_type]).to be_nil
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for an RRN that does not exist or is not applicable" do
    let(:rrn) { "0000-1111-2222-3333-5555" }

    before do
      allow(bus_gateway).to receive(:search_by_rrn).with(rrn).and_return nil
    end

    it "returns nil" do
      expect(use_case.execute(rrn:)).to be_nil
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details for an RRN for an assessment that has been superseded" do
    let(:later_rrn) { "0000-2222-4444-6666-8888" }

    before do
      allow(bus_gateway).to receive(:search_by_rrn).with(rrn).and_return bus_details
      assessment_summary[:superseded_by] = later_rrn
      allow(summary_use_case).to receive(:execute).with(rrn).and_return assessment_summary
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "RdSAP-Schema-20.0.0",
      })
    end

    it "returns the assessment reference passed to it from the gateway" do
      expect(use_case.execute(rrn:).rrn).to eq later_rrn
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details with an RRN for a DEC" do
    before do
      bus_details["report_type"] = "DEC"
      allow(bus_gateway).to receive(:search_by_rrn).with(rrn).and_return bus_details
    end

    it "raises an invalid assessment type error" do
      expect { use_case.execute(rrn:) }.to raise_error described_class::InvalidAssessmentTypeException
    end
  end

  context "when fetching BUS (Boiler Upgrade Scheme) details with an RRN for an AC-CERT" do
    before do
      bus_details["report_type"] = "AC-CERT"
      allow(bus_gateway).to receive(:search_by_rrn).with(rrn).and_return bus_details
    end

    it "raises an invalid assessment type error" do
      expect { use_case.execute(rrn:) }.to raise_error described_class::InvalidAssessmentTypeException
    end
  end
end
