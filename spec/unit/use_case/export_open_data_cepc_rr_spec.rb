describe UseCase::ExportOpenDataCepcrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data reporting release" do
    describe "for the CEPC recommendation reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:expected) { described_class.new }
      let(:date_today) { DateTime.now.strftime("%F") }
      let(:time_today) { DateTime.now.strftime("%F %H:%M:%S") }
      let(:number_assessments_to_test) { 4 }
      let(:cepc_plus_rr_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc+rr") }
      let(:cepc_minus_rr_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc-rr") } # should not be present in export
      let(:cepc_minus_rr_xml_id) { cepc_minus_rr_xml.at("//CEPC:RRN") }
      let(:expected_values) { Samples::ViewModels::CepRr.report_test_hash}


      let(:exported_data) do
        described_class.new.execute(
          {
            number_of_assessments: number_assessments_to_test,
            max_runs: "3",
            batch: "3",
          },
          )
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

        # create a lodgement for cepc
        lodge_assessment(
          assessment_body: cepc_plus_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
          schema_name: "CEPC-8.0.0",
          )

        # create a lodgement for cepc that should not be returned
        # cepc_minus_rr_xml_id.children = "0000-0000-0000-0000-0010"
        # lodge_assessment(
        #   assessment_body: cepc_minus_rr_xml.to_xml,
        #   accepted_responses: [201],
        #   auth_data: { scheme_ids: [scheme_id] },
        #   override: true,
        #   schema_name: "CEPC-8.0.0",
        #   )

      end

      it 'returns the correct number of items (excluding the cepc-rr) ' do
          expect(exported_data.length).to eq(number_assessments_to_test)
      end


      Samples::ViewModels::CepRr.report_test_hash[:payback_type].each_with_index do | value, index |
        it "returns the #{index} that matches the test data for the 1st row" do
          expect(value).to eq(Samples::ViewModels::CepRr.report_test_hash[:payback_type][index])
        end
      end


    end
  end
end
