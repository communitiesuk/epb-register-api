describe Gateway::RetrofitFundingSchemeGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

  context "when expecting to find one assessment" do
    before do
      add_super_assessor(scheme_id:)

      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
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
      current_band: "e",
    }

    context "when there is only a single assessment for a UPRN" do
      it "searches by uprn and fetches data where one match exists" do
        result = gateway.fetch_by_uprn("000000000000")
        expect(result).to be_a(Domain::AssessmentRetrofitFundingDetails)
        expect(result.to_hash).to eq expected_retrofit_funding_details_hash
      end
    end

    context "when there is more than one assessment for a UPRN" do
      let(:latest_rrn) { "0000-0000-0000-0000-0013" }

      before do
        superseded_rdsap = rdsap_xml.clone
        superseded_rdsap.at("RRN").children = latest_rrn
        superseded_rdsap.at("Registration-Date").children = "2015-05-04"

        lodge_assessment(
          assessment_body: superseded_rdsap.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      end

      it "searches by uprn and fetches data where one match exists" do
        result = gateway.fetch_by_uprn("000000000000")
        expect(result).to be_a(Domain::AssessmentRetrofitFundingDetails)
        expect(result.to_hash).to eq expected_retrofit_funding_details_hash
      end
    end
  end
end
