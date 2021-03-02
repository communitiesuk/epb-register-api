describe UseCase::ExportOpenDataDecrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data reporting release" do
    describe "for the DEC recommendation reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:date_today) { DateTime.now.strftime("%F") }
      let(:export_object) { described_class.new }
      let(:number_of_recommendations_expected) { 5 }
      let(:dec_plus_rr_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec+rr") }
      let(:dec_plus_rr_xml_id) { dec_plus_rr_xml.at("//RRN") }
      let(:dec_plus_rr_xml_date) { dec_plus_rr_xml.at("//Registration-Date") }
      let(:rr_minus_dec_xml) do
        Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec-rr")
      end
      let(:rr_minus_dec_xml_id) { rr_minus_dec_xml.at("RRN") }
      let(:rr_minus_dec_xml_date) { rr_minus_dec_xml.at("//Registration-Date") }
      let(:exported_data) do
        export_object
          .execute("2019-07-01", 1)
          .sort_by! { |key| key[:recommendation_item] }
      end

      let(:statistics) do
        gateway = Gateway::OpenDataLogGateway.new
        gateway.fetch_log_statistics
      end

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

        # create a lodgement for dec whose date is valid
        lodge_assessment(
          assessment_body: dec_plus_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        # create a lodgement for rr without a DEC that should not be returned
        rr_minus_dec_xml_id.children = "0000-0000-0000-0000-0010"
        lodge_assessment(
          assessment_body: rr_minus_dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )
      end

      it "returns the correct number of items (excluding the dec-rr) " do
        expect(exported_data.length).to eq(number_of_recommendations_expected)
      end

      it "exports the recommendations in the expected format" do
        expect(exported_data[0]).to eq(
          {
            payback_type: "short",
            cO2_Impact: "MEDIUM",
            recommendation:
              "Consider thinking about maybe possibly getting a solar panel but only one.",
            recommendation_code: "ECP-L5",
            recommendation_item: 1,
            assessment_id:
              "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4",
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
            assessment_id:
              "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4",
          },
        )
      end

      it "returns 5 rows when called with a different task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(5)
        expect(export_object.execute("2019-07-01", 2).length).to eq(5)
      end

      it "returns 5 rows when no task id is passed" do
        expect(export_object.execute("2019-07-01").length).to eq(5)
        expect(statistics.first["num_rows"]).to eq(1)
      end

      it "returns 0 rows when called with the existing task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(5)
        expect(export_object.execute("2019-07-01", 1).length).to eq(0)
      end
    end
  end
end
