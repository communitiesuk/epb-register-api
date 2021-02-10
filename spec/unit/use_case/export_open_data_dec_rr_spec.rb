describe UseCase::ExportOpenDataDecrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data reporting release" do
    describe "for the DEC recommendation reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:expected) { described_class.new }
      let(:date_today) { DateTime.now.strftime("%F") }

      let(:number_of_recommendations_expected) { 5 }
      let(:dec_plus_rr_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec+rr") }
      let(:dec_plus_rr_xml_id) { dec_plus_rr_xml.at("//RRN") }
      let(:dec_plus_rr_xml_date) { dec_plus_rr_xml.at("//Registration-Date") }
      let(:rr_minus_dec_xml) do
        Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec-rr")
      end
      let(:rr_minus_dec_xml_id) { rr_minus_dec_xml.at("RRN") }
      let(:rr_minus_dec_xml_date) { rr_minus_dec_xml.at("//Registration-Date") }
      let(:exported_data) { described_class.new.execute(1, "2019-07-01") }

      let(:statistics) do
        gateway = Gateway::OpenDataLogGateway.new
        gateway.get_statistics
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
            rrn: "0000-0000-0000-0000-0001",
          },
        )
      end

      it "exports the data ordered by payback_type" do
        order_of_payback_type =
          exported_data.map { |recommendation| recommendation[:payback_type] }
        expect(order_of_payback_type).to eq %w[short short medium long other]
      end
    end
  end
end
