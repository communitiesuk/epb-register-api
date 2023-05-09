describe UseCase::FetchAssessmentForRetrofitFundingScheme do
  subject(:use_case) { described_class.new(retrofit_funding_scheme_gateway:, assessments_search_gateway:, domestic_digest_gateway:) }

  let(:retrofit_funding_scheme_gateway) { instance_double Gateway::RetrofitFundingSchemeGateway }

  let(:assessments_search_gateway) { instance_double Gateway::AssessmentsSearchGateway }

  let(:domestic_digest_gateway) { instance_double Gateway::DomesticDigestGateway }

  let(:search_results) do
    [{
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
  end

  context "when expecting to find an assessment" do
    uprn = "000000000000"
    rrn = "0000-0000-0000-0000-0000"
    xml = Samples.xml "RdSAP-Schema-20.0.0"

    before do
      allow(retrofit_funding_scheme_gateway).to receive(:find_by_uprn).with(uprn).and_return(rrn)
      allow(assessments_search_gateway).to receive(:search_by_assessment_id).with(rrn).and_return(search_results)
      allow(domestic_digest_gateway).to receive(:fetch_by_rrn).with(rrn).and_return({
        "xml" => xml,
        "schema_type" => "RdSAP-Schema-20.0.0",
      })
    end

    expected_retrofit_funding_details_hash = {
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
      expiry_date: "2030-05-03",
      current_band: "e",
      property_type: "Mid-terrace house",
      built_form: "Semi-Detached",
    }

    it "returns the expected data" do
      result = use_case.execute(uprn)
      expect(result).to be_a(Domain::AssessmentRetrofitFundingDetails)
      expect(result.to_hash).to eq expected_retrofit_funding_details_hash
    end
  end

  context "when expecting to find no assessments" do
    uprn = "000000000001"

    before do
      allow(retrofit_funding_scheme_gateway).to receive(:find_by_uprn).with(uprn).and_return(nil)
    end

    it "returns nil" do
      result = use_case.execute(uprn)
      expect(result).to be_nil
    end
  end
end
