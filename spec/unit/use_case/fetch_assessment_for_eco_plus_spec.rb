describe UseCase::FetchAssessmentForEcoPlus do
  subject(:use_case) { described_class.new(domestic_digest_gateway:, assessments_search_gateway:) }

  let(:domestic_digest_gateway) { instance_double Gateway::DomesticDigestGateway }
  let(:assessments_search_gateway) { instance_double Gateway::AssessmentsSearchGateway }

  context "when an RRN matches an RdSAP assessment for which the Eco Plus scheme has access to" do
    rrn = "0123-1234-2345-3456-4567"
    xml = Samples.xml "RdSAP-Schema-20.0.0"
    search_results = [{
      address_id: "UPRN-000000000000",
      address_line1: "1 Some Street",
      address_line2: "",
      address_line3: "",
      address_line4: "",
      current_energy_efficiency_band: "e",
      date_of_registration: "2020-05-04",
      date_of_expiry: Time.new(2030, 5, 3).to_date,
      postcode: "A0 0AA",
      town: "Whitbury",
    }]

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "RdSAP-Schema-20.0.0",
      })
      allow(assessments_search_gateway).to receive(:search_by_assessment_id).with(rrn).and_return(search_results)
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
      uprn: "000000000000",
      lodgement_date: "2020-05-04",
      current_energy_efficiency_rating: 50,
      current_energy_efficiency_band: "e",
      potential_energy_efficiency_rating: 72,
      potential_energy_efficiency_band: "c",
      property_type: "Mid-terrace house",
      built_form: "Semi-Detached",
      main_heating_description: "boiler with radiators or underfloor heating",
      walls_description: [
        "Solid brick, as built, no insulation (assumed)",
        "Cavity wall, as built, insulated (assumed)",
      ],
      roof_description: [
        "Pitched, 25 mm loft insulation",
        "Pitched, 250 mm loft insulation",
      ],
      cavity_wall_insulation_recommended: false,
      loft_insulation_recommended: false,
    }

    describe "#execute" do
      it "invokes without error" do
        expect { use_case.execute(rrn:) }.not_to raise_error
      end

      it "returns a domain object" do
        details = use_case.execute(rrn:)
        expect(details).to be_a Domain::AssessmentEcoPlusDetails
      end

      it "contains the expected details" do
        details = use_case.execute(rrn:)
        expect(details.to_hash).to eq expected
      end
    end
  end

  context "when an RRN matches an SAP assessment for which the Eco Plus scheme has access to" do
    rrn = "0123-1234-2345-3456-4569"
    xml = Samples.xml("SAP-Schema-16.3", "sap")
    search_results = [{
      address_id: "UPRN-000000000000",
      address_line1: "1 Some Street",
      address_line2: "Some Area",
      address_line3: "Some County",
      address_line4: "",
      current_energy_efficiency_band: "e",
      date_of_registration: "2020-05-04",
      date_of_expiry: Time.new(2030, 5, 3).to_date,
      postcode: "A0 0AA",
      town: "Whitbury",
    }]

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "SAP-Schema-16.3",
      })
      allow(assessments_search_gateway).to receive(:search_by_assessment_id).with(rrn).and_return(search_results)
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
      uprn: "000000000000",
      lodgement_date: "2020-05-04",
      current_energy_efficiency_rating: 50,
      current_energy_efficiency_band: "e",
      potential_energy_efficiency_rating: 72,
      potential_energy_efficiency_band: "c",
      property_type: "Mid-terrace house",
      built_form: "Detached",
      main_heating_description: "boiler with radiators or underfloor heating",
      walls_description: [
        "Brick walls",
        "Brick walls",
      ],
      roof_description: [
        "Slate roof",
        "slate roof",
      ],
      cavity_wall_insulation_recommended: true,
      loft_insulation_recommended: true,
    }

    it "contains the expected details" do
      details = use_case.execute(rrn:)
      expect(details.to_hash).to eq expected
    end
  end

  context "when the domestic gateway does not find the RRN" do
    rrn = "0123-1234-2345-3456-0000"

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return(nil)
    end

    it "returns nil" do
      details = use_case.execute(rrn:)
      expect(details).to be_nil
    end
  end

  context "when the assessments search gateway does not find the RRN" do
    rrn = "0123-1234-2345-3456-0000"
    xml = Samples.xml "RdSAP-Schema-20.0.0"

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "RdSAP-Schema-20.0.0",
      })
      allow(assessments_search_gateway).to receive(:search_by_assessment_id).with(rrn).and_return([])
    end

    it "returns nil" do
      details = use_case.execute(rrn:)
      expect(details).to be_nil
    end
  end
end
