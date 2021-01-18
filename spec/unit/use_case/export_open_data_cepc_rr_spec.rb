describe UseCase::ExportOpenDataCepcrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data reporting release" do
    describe "for the CEPC recommendation reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:expected) { described_class.new }
      let(:date_today) { DateTime.now.strftime("%F") }
      # number in test in 2 x 4 (number of recomendations in each lodgement)
      let(:number_assessments_to_test) { 5 }
      let(:cepc_plus_rr_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc+rr") }
      let(:cepc_plus_rr_xml_id) { cepc_plus_rr_xml.at("//CEPC:RRN") }
      let(:cepc_plus_rr_xml_date) { cepc_plus_rr_xml.at("//CEPC:Registration-Date") }
      let(:cepc_minus_rr_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc-rr") } # should not be present in export
      let(:cepc_minus_rr_xml_id) { cepc_minus_rr_xml.at("//CEPC:RRN") }
      let(:cepc_plus_rr_xml_date) { cepc_plus_rr_xml.at("//CEPC:Registration-Date") }
      let(:expected_values) { Samples::ViewModels::CepRr.report_test_hash}



      let(:exported_data) {
        described_class.new.execute
      }


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
          assessment_body: cepc_plus_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
          schema_name: "CEPC-8.0.0",
          )



        # @TODO: create a lodgement for CEPC  whose date is not valid

        # create a lodgement for cepc that should not be returned
        cepc_minus_rr_xml_id.children = "0000-0000-0000-0000-0010"
        lodge_assessment(
          assessment_body: cepc_minus_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
          schema_name: "CEPC-8.0.0",
          )


      end

      it 'returns the correct number of items (excluding the cepc-rr) ' do
          expect(exported_data.length).to eq(number_assessments_to_test)
      end



      it 'should export the data for short in the first 2 rows' do
        expect(exported_data[0]).to eq({:cO2_Impact=>"HIGH",
                                        :recommendation=>"Consider replacing T8 lamps with retrofit T5 conversion kit.",
                                        :recommendation_code=>"ECP-L5",
                                        :recommendation_item=>1,
                                        :rrn=>"0000-0000-0000-0000-0001"})

        expect(exported_data[1]).to eq({:cO2_Impact=>"LOW",
                                        :recommendation=>"Introduce HF (high frequency) ballasts for fluorescent tubes: Reduced number of fittings required.",
                                        :recommendation_code=>"ECP-L5",
                                        :recommendation_item=>2,
                                        :rrn=>"0000-0000-0000-0000-0001"})
      end


    end
  end
end
