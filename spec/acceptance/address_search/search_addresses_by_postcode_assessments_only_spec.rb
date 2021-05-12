describe "Acceptance::AddressSearch::ByPostcode::AssessmentSource", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  context "when there are no address base entries for a postcode" do
    let(:domestic_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
    let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }

    let(:scheme_id) { add_scheme_and_get_id }

    let(:response) do
      JSON.parse(
        assertive_get(
          "/api/search/addresses?postcode=A0%200AA",
          [200],
          true,
          {},
          %w[address:search],
        ).body,
        symbolize_names: true,
      )
    end

    before(:each) do
      add_assessor(
        scheme_id,
        "SPEC000000",
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
          nonDomesticDec: "ACTIVE",
          domesticRdSap: "ACTIVE",
          domesticSap: "ACTIVE",
          nonDomesticSp3: "ACTIVE",
          nonDomesticCc4: "ACTIVE",
          gda: "ACTIVE",
        ),
      )
    end

    it "returns addresses from expired assessments" do
      domestic_xml.at("Registration-Date").content =
        Date.today.prev_year(11).strftime("%Y-%m-%d")

      domestic_xml.at("UPRN").remove

      lodge_assessment(
        assessment_body: domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )

      expect(response[:data][:addresses]).to eq(
        [
          {
            line1: "1 Some Street",
            line2: nil,
            line3: nil,
            line4: nil,
            postcode: "A0 0AA",
            town: "Whitbury",
            addressId: "RRN-0000-0000-0000-0000-0000",
            source: "PREVIOUS_ASSESSMENT",
            existingAssessments: [
              {
                assessmentId: "0000-0000-0000-0000-0000",
                assessmentStatus: "EXPIRED",
                assessmentType: "RdSAP",
              },
            ],
          },
        ],
      )
    end

    it "returns addresses from entered assessments" do
      non_domestic_xml.at(
        "//CEPC:UPRN",
        "CEPC" => "https://epbr.digital.communities.gov.uk/xsd/cepc",
      ).remove
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      non_domestic_xml.at(
        "//CEPC:RRN",
        "CEPC" => "https://epbr.digital.communities.gov.uk/xsd/cepc",
      ).content =
        "0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      expect(response[:data][:addresses]).to eq(
        [
          {
            line1: "Some Unit",
            line2: "2 Lonely Street",
            line3: "Some Area",
            line4: "Some County",
            postcode: "A0 0AA",
            town: "Whitbury",
            addressId: "RRN-0000-0000-0000-0000-0000",
            source: "PREVIOUS_ASSESSMENT",
            existingAssessments: [
              {
                assessmentId: "0000-0000-0000-0000-0000",
                assessmentStatus: "ENTERED",
                assessmentType: "CEPC",
              },
              {
                assessmentId: "0000-0000-0000-0000-0002",
                assessmentStatus: "ENTERED",
                assessmentType: "CEPC",
              },
            ],
          },
        ],
      )
    end
  end
end
