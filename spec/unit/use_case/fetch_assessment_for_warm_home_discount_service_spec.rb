describe UseCase::FetchAssessmentForWarmHomeDiscountService do
  subject(:use_case) { described_class.new(domestic_digest_gateway:, summary_use_case:) }

  let(:domestic_digest_gateway) { instance_double Gateway::DomesticDigestGateway }

  let(:summary_use_case) { instance_double UseCase::AssessmentSummary::Fetch }

  context "when an RRN matches an RdSAP assessment for which Warm Home Discount Service details can be provided" do
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
      total_floor_area: 55,
      type_of_property: "House",
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
      clone[:total_floor_area] = nil
      clone
    end

    context "with an RRN that is the property's latest assessment" do
      before do
        allow(summary_use_case).to receive(:execute).with(rrn).and_return({
          superseded_by: nil,
        })
      end

      it "returns a domain object containing the expected Warm Home Discount Service details", aggregate_failures: true do
        details = use_case.execute(rrn:)
        expect(details).to be_a Domain::AssessmentWarmHomeDiscountServiceDetails
        expect(details.to_hash).to eq expected_latest
      end
    end

    context "with an RRN that is not the property's latest assessment" do
      before do
        allow(summary_use_case).to receive(:execute).with(rrn).and_return({
          superseded_by: "0000-1111-2222-3333-6666",
        })
      end

      it "returns a domain object containing the expected Warm Home Discount Service details", aggregate_failures: true do
        details = use_case.execute(rrn:)
        expect(details).to be_a Domain::AssessmentWarmHomeDiscountServiceDetails
        expect(details.to_hash).to eq expected_not_latest
      end
    end

    context "when there are null values in the XML" do
      before do
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        domestic_rdsap_xml.at("Dwelling-Type").children.remove
        domestic_rdsap_xml.at("Built-Form").children.remove
        domestic_rdsap_xml.at("Construction-Age-Band").children.remove
        domestic_rdsap_xml.at("Total-Floor-Area").children.remove

        allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
          "xml" => domestic_rdsap_xml.to_xml,
          "schema_type" => "RdSAP-Schema-20.0.0",
        })
        allow(summary_use_case).to receive(:execute).with(rrn).and_return({
          superseded_by: nil,
        })
      end

      it "returns a domain object containing the expected Warm Home Discount Service details", aggregate_failures: true do
        details = use_case.execute(rrn:)
        expect(details).to be_a Domain::AssessmentWarmHomeDiscountServiceDetails
        expect(details.to_hash).to eq expected_with_nulls
      end
    end
  end

  context "when an RRN matches a SAP assessment for which Warm Home Discount Service details can be provided" do
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
      total_floor_area: 69,
      type_of_property: "House",
    }

    it "returns a domain object containing the expected Warm Home Discount Service details", aggregate_failures: true do
      details = use_case.execute(rrn:)
      expect(details).to be_a Domain::AssessmentWarmHomeDiscountServiceDetails
      expect(details.to_hash).to eq expected
    end
  end

  context "when an RRN matches an older SAP assessment for which Warm Home Discount Service details can be provided" do
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
      property_type: nil,
      lodgement_date: "2020-05-04",
      property_age_band: nil,
      total_floor_area: 98,
      type_of_property: "House",
    }

    it "returns a domain object containing the expected Warm Home Discount Service details", aggregate_failures: true do
      details = use_case.execute(rrn:)
      expect(details).to be_a Domain::AssessmentWarmHomeDiscountServiceDetails
      expect(details.to_hash).to eq expected
    end
  end

  context "when an RRN does not match an assessment for which Warm Home Discount Service details can be provided" do
    rrn = "5555-5555-5555-5555-5555"

    before do
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return(nil)
    end

    it "returns nil" do
      expect(use_case.execute(rrn:)).to be_nil
    end
  end
end
