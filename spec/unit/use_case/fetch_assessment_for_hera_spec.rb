describe UseCase::FetchAssessmentForHera do
  subject(:use_case) { described_class.new(hera_gateway: hera_gateway, summary_use_case: summary_use_case) }

  let(:hera_gateway) { instance_double Gateway::HomeEnergyRetrofitAdviceGateway }

  let(:summary_use_case) { instance_double UseCase::AssessmentSummary::Fetch }

  context "when an RRN matches an RdSAP assessment for which HERA details can be provided" do
    rrn = "0000-1111-2222-3333-4444"
    xml = Samples.xml "RdSAP-Schema-20.0.0"

    before do
      allow(hera_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "RdSAP-Schema-20.0.0",
      })
    end

    expected = {
      type_of_assessment: "RdSAP",
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
      built_form: "2",
      property_age_band: "K",
      walls_description: [
        "Solid brick, as built, no insulation (assumed)",
        "Cavity wall, as built, insulated (assumed)",
      ],
      floor_description: [
        "Suspended, no insulation (assumed)",
        "Solid, insulated (assumed)",
      ],
      roof_description: [
        "Pitched, 25 mm loft insulation",
        "Pitched, 250 mm loft insulation",
      ],
      windows_description: [
        "Fully double glazed",
      ],
      main_heating_description: "2",
      main_fuel_type: "26",
      has_hot_water_cylinder: false,
    }

    let(:expected_not_latest) { expected }
    let(:expected_latest) do
      clone = expected_not_latest.clone
      clone[:is_latest_assessment_for_address] = true
      clone
    end

    context "with an RRN that is the property's latest assessment" do
      before do
        allow(summary_use_case).to receive(:execute).with(rrn).and_return({
          superseded_by: nil,
        })
      end

      it "returns a domain object containing the expected HERA details", aggregate_failures: true do
        details = use_case.execute(rrn: rrn)
        expect(details).to be_a Domain::AssessmentHeraDetails
        expect(details.to_hash).to eq expected_latest
      end
    end

    context "with an RRN that is not the property's latest assessment" do
      before do
        allow(summary_use_case).to receive(:execute).with(rrn).and_return({
          superseded_by: "0000-1111-2222-3333-6666",
        })
      end

      it "returns a domain object containing the expected HERA details", aggregate_failures: true do
        details = use_case.execute(rrn: rrn)
        expect(details).to be_a Domain::AssessmentHeraDetails
        expect(details.to_hash).to eq expected_not_latest
      end
    end
  end

  context "when an RRN matches a SAP assessment for which HERA details can be provided" do
    rrn = "5555-6666-7777-8888-9999"

    xml = Samples.xml "SAP-Schema-18.0.0"

    before do
      allow(hera_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "SAP-Schema-18.0.0",
      })
      allow(summary_use_case).to receive(:execute).with(rrn).and_return({
        superseded_by: nil,
      })
    end

    expected = {
      type_of_assessment: "SAP",
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
      built_form: "1",
      property_age_band: "1750",
      walls_description: [
        "Brick walls",
        "Brick walls",
      ],
      floor_description: [
        "Tiled floor",
        "Tiled floor",
      ],
      roof_description: [
        "Slate roof",
        "slate roof",
      ],
      windows_description: [
        "Glass window",
      ],
      main_heating_description: "5",
      main_fuel_type: "36",
      has_hot_water_cylinder: true,
    }

    it "returns a domain object containing the expected HERA details", aggregate_failures: true do
      details = use_case.execute(rrn: rrn)
      expect(details).to be_a Domain::AssessmentHeraDetails
      expect(details.to_hash).to eq expected
    end
  end

  context "when an RRN does not match an assessment for which HERA details can be provided" do
    rrn = "5555-5555-5555-5555-5555"

    before do
      allow(hera_gateway).to receive(:fetch_by_rrn).with(rrn).and_return(nil)
    end

    it "returns nil" do
      expect(use_case.execute(rrn: rrn)).to be_nil
    end
  end
end
