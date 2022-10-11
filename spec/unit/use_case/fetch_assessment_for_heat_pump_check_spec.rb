describe UseCase::FetchAssessmentForHeatPumpCheck do
  subject(:use_case) { described_class.new(domestic_digest_gateway:, summary_use_case:) }

  let(:domestic_digest_gateway) { instance_double Gateway::DomesticDigestGateway }

  let(:summary_use_case) { instance_double UseCase::AssessmentSummary::Fetch }

  context "when an RRN matches an RdSAP assessment for which Heat Pump Check details can be provided" do
    rrn = "0000-1111-2222-3333-4444"
    xml = Samples.xml "RdSAP-Schema-20.0.0"

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "RdSAP-Schema-20.0.0",
      })
    end

    expected = {
      address: {
        address_line1: "1 Some Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      lodgement_date: "2020-05-04",
      is_latest_assessment_for_address: false,
      property_type: "Mid-terrace house",
      built_form: "Semi-Detached",
      property_age_band: "2007-2011",
      walls_description: [
        "Solid brick, as built, no insulation (assumed)",
        "Cavity wall, as built, insulated (assumed)",
      ],
      roof_description: [
        "Pitched, 25 mm loft insulation",
        "Pitched, 250 mm loft insulation",
      ],
      windows_description: [
        "Fully double glazed",
      ],
      main_fuel_type: "mains gas (not community)",
      total_floor_area: 55,
      has_mains_gas: true,
      current_energy_efficiency_rating: 50,
    }

    let(:expected_not_latest) { expected }
    let(:expected_latest) do
      clone = expected_not_latest.clone
      clone[:is_latest_assessment_for_address] = true
      clone
    end
    let(:expected_with_nulls) do
      clone = expected_latest.clone
      clone[:property_type] = nil
      clone[:built_form] = nil
      clone[:property_age_band] = nil
      clone[:walls_description] = []
      clone[:roof_description] = []
      clone[:windows_description] = []
      clone[:main_fuel_type] = nil
      clone[:total_floor_area] = nil
      clone[:has_mains_gas] = nil
      clone[:current_energy_efficiency_rating] = 0 # This will never be null as it is cast to an integer in the view model
      clone
    end

    context "with an RRN that is the property's latest assessment" do
      before do
        allow(summary_use_case).to receive(:execute).with(rrn).and_return({
          superseded_by: nil,
        })
      end

      it "returns a domain object containing the expected Heat Pump Check details", aggregate_failures: true do
        details = use_case.execute(rrn:)
        expect(details).to be_a Domain::AssessmentForHeatPumpCheck
        expect(details.to_hash).to eq expected_latest
      end
    end

    context "with an RRN that is not the property's latest assessment" do
      before do
        allow(summary_use_case).to receive(:execute).with(rrn).and_return({
          superseded_by: "0000-1111-2222-3333-6666",
        })
      end

      it "returns a domain object containing the expected Heat Pump Check details", aggregate_failures: true do
        details = use_case.execute(rrn:)
        expect(details).to be_a Domain::AssessmentForHeatPumpCheck
        expect(details.to_hash).to eq expected_not_latest
      end
    end

    context "when there are null values in the XML" do
      before do
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        domestic_rdsap_xml.at("Dwelling-Type").children.remove
        domestic_rdsap_xml.at("Built-Form").children.remove
        domestic_rdsap_xml.at("Construction-Age-Band").children.remove
        domestic_rdsap_xml.search("Wall").children.remove
        domestic_rdsap_xml.search("Roof").children.remove
        domestic_rdsap_xml.search("Window").children.remove
        domestic_rdsap_xml.at("Main-Fuel-Type").children.remove
        domestic_rdsap_xml.at("Total-Floor-Area").children.remove
        domestic_rdsap_xml.at("Mains-Gas").children.remove
        domestic_rdsap_xml.at("Energy-Rating-Current").children.remove

        allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
          "xml" => domestic_rdsap_xml.to_xml,
          "schema_type" => "RdSAP-Schema-20.0.0",
        })
        allow(summary_use_case).to receive(:execute).with(rrn).and_return({
          superseded_by: nil,
        })
      end

      it "returns a domain object containing the expected Heat Pump Check details", aggregate_failures: true do
        details = use_case.execute(rrn:)
        expect(details).to be_a Domain::AssessmentForHeatPumpCheck
        expect(details.to_hash).to eq expected_with_nulls
      end
    end
  end

  context "when an RRN matches a SAP assessment for which Heat Pump Check details can be provided" do
    rrn = "5555-6666-7777-8888-9999"

    xml = Samples.xml "SAP-Schema-18.0.0"

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "SAP-Schema-18.0.0",
      })
      allow(summary_use_case).to receive(:execute).with(rrn).and_return({
        superseded_by: nil,
      })
    end

    expected = {
      address: {
        address_line1: "1 Some Street",
        address_line2: "Some Area",
        address_line3: "Some County",
        address_line4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      lodgement_date: "2020-05-04",
      is_latest_assessment_for_address: true,
      property_type: "Mid-terrace house",
      built_form: "Detached",
      property_age_band: "1750",
      walls_description: [
        "Brick walls",
        "Brick walls",
      ],
      roof_description: [
        "Slate roof",
        "slate roof",
      ],
      windows_description: [
        "Glass window",
      ],
      main_fuel_type: "Electricity: electricity sold to grid",
      total_floor_area: 69,
      has_mains_gas: nil,
      current_energy_efficiency_rating: 50,
    }

    it "returns a domain object containing the expected Heat Pump Check details", aggregate_failures: true do
      details = use_case.execute(rrn:)
      expect(details).to be_a Domain::AssessmentForHeatPumpCheck
      expect(details.to_hash).to eq expected
    end
  end

  context "when an RRN matches an older SAP assessment for which Heat Pump Check details can be provided" do
    rrn = "5555-6666-7777-8888-9999"

    sap_xml = Samples.xml "SAP-Schema-10.2", "rdsap"
    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => sap_xml,
        "schema_type" => "SAP-Schema-10.2",
      })
      allow(summary_use_case).to receive(:execute).with(rrn).and_return({
        superseded_by: nil,
      })
    end

    expected = {
      address:
        { address_line1: "1 Some Street",
          address_line2: "Some Area",
          address_line3: "Some County",
          address_line4: "",
          town: "Whitbury",
          postcode: "A0 0AA" },
      built_form: "Detached",
      is_latest_assessment_for_address: true,
      lodgement_date: "2020-05-04",
      main_fuel_type: "electricity",
      property_age_band: nil,
      property_type: nil,
      roof_description: ["Slate roof", "slate roof"],
      walls_description: ["Brick walls", "Brick walls"],
      windows_description: ["Glass window"],
      total_floor_area: 98,
      has_mains_gas: nil,
      current_energy_efficiency_rating: 50,
    }

    it "returns a domain object containing the expected Heat Pump Check details", aggregate_failures: true do
      details = use_case.execute(rrn:)
      expect(details).to be_a Domain::AssessmentForHeatPumpCheck
      expect(details.to_hash).to eq expected
    end
  end

  context "when an RRN does not match an assessment for which Heat Pump Check details can be provided" do
    rrn = "5555-5555-5555-5555-5555"

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return(nil)
    end

    it "returns nil" do
      expect(use_case.execute(rrn:)).to be_nil
    end
  end
end
