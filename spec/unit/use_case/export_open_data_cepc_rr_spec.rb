describe UseCase::ExportOpenDataCepcrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data reporting release" do
    describe "for the DEC reccomemdation reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:expected) { described_class.new }
      let(:date_today) { DateTime.now.strftime("%F") }
      let(:time_today) { DateTime.now.strftime("%F %H:%M:%S") }
      let(:number_assessments_to_test) { 1 }
      let(:cepc_rr_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc+rr") }
      let(:cepc_rr_assessment_id) { cepc_rr_xml.at("RRN") }
      let(:cepc_rr_assessment_date) { cepc_rr_xml.at("Registration-Date") }
      let(:expected_values) do
        Samples::ViewModels::Dec.report_test_hash.merge(
          { lodgement_date: date_today, lodgement_datetime: time_today },
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

        # create two lodgements
        lodge_assessment(
          assessment_body: cepc_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
          schema_name: "CEPC-8.0.0",
          )


        # create two lodgements
        lodge_assessment(
          assessment_body: cepc_rr_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
          schema_name: "CEPC-8.0.0",
          )
        # cepc_rr_assessment_id.children = "0000-0000-0000-0000-0001"
        # lodge_assessment(
        #   assessment_body: cepc_rr_xml.to_xml,
        #   accepted_responses: [201],
        #   auth_data: { scheme_ids: [scheme_id] },
        #   override: true,
        #   schema_name: "CEPC-8.0.0",
        #   )

      end

      let(:exported_data) do
        described_class.new.execute(
          {
            number_of_assessments: number_assessments_to_test,
            max_runs: "3",
            batch: "3",
          },
          )
        end
        # @TODO once tests have completed refactor to write one assertion for each row and compare to hash rather than for each column
        it "returns the correct number of assessments in the Data (the number of assessments lodged + the hash of recommendations)" do
          expect(exported_data.length).to eq(number_assessments_to_test * 2)
        end


    end
  end
end

