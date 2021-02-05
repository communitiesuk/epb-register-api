describe UseCase::ExportOpenDataDecrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data reporting release" do
    describe "for the DEC recommendation reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:expected) { described_class.new }
      let(:date_today) { DateTime.now.strftime("%F") }

      # number in test in 2 x 4 (number of recommendations in each lodgement)
      let(:number_assessments_to_test) { 5 }
      let(:dec_plus_rr_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec+rr") }
      let(:dec_plus_rr_xml_id) { dec_plus_rr_xml.at("//RRN") }
      let(:dec_plus_rr_xml_date) { dec_plus_rr_xml.at("//Registration-Date") }
      let(:dec_minus_rr_xml) do
        Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec-rr")
      end
      let(:dec_minus_rr_xml_id) { dec_minus_rr_xml.at("RRN") }
      let(:dec_minus_rr_xml_date) { dec_minus_rr_xml.at("//Registration-Date") }
      let(:exported_data) { described_class.new.execute }

      before do
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

        # create a lodgement for cepc whose date valid
        lodge_assessment(
          assessment_body: dec_plus_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        # create a lodgement for cepc that should not be returned
        dec_minus_rr_xml_id.children = "0000-0000-0000-0000-0010"

        # create a lodgement for cepc whose date valid
        lodge_assessment(
          assessment_body: dec_minus_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        # @TODO: create a lodgement for DEC  whose date is not valid
      end

      it "returns the correct number of items (excluding the dec-rr) " do
        expect(exported_data.length).to eq(number_assessments_to_test)
      end

      it "should export the data for short in the first 2 rows" do
        expect(exported_data[0]).to eq(
          {
            payback_type: "short",
            cO2_Impact: "MEDIUM",
            recommendation:
              "Consider thinking about maybe possibly getting a solar panel but only one.",
            recommendation_code: "ECP-L5",
            recommendation_item: 1,
            rrn: "0000-0000-0000-0000-0001",
          },
        )

        expect(exported_data[1]).to eq(
          {
            payback_type: "short",
            cO2_Impact: "LOW",
            recommendation:
              "Consider introducing variable speed drives (VSD) for fans, pumps and compressors.",
            recommendation_code: "EPC-L7",
            recommendation_item: 2,
            rrn: "0000-0000-0000-0000-0001",
          },
        )
      end
    end
  end
end
