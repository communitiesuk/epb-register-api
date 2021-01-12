describe UseCase::ExportOpenDataDec do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the DEC and reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:dec_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec") }
      let(:number_assessments_to_test) { 1 }
      let(:expected_values) { Samples::ViewModels::Dec.report_test_hash }
      let(:expected_values_row_1) do
        Samples.update_test_hash(
          expected_values,
          { rrn: "0000-0000-0000-0000-0001", lodgement_date: "2018-05-04" },
        )
      end

      # @TODO filter data correctly for DEC
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
        lodge_assessment(
          assessment_body: dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        # @TODO figure out hot run second lodgement for DEC
        # dec_xml.children = "0000-0000-0000-0000-0002"
        # lodge_assessment(
        #   assessment_body: dec_xml.to_xml,
        #   accepted_responses: [201],
        #   auth_data: { scheme_ids: [scheme_id] },
        #   override: true,
        #   schema_name: "CEPC-8.0.0",
        #   )
      end

      # @TODO once tests have completed refactor to write one assertion for each row and compare to hash rather than for each column

      it "returns the correct number of assessments in the CSV" do
        expect(exported_data.length).to eq(number_assessments_to_test)
      end

      # 1st row to test
      # write at test for each key in test hash
      Samples::ViewModels::Dec
        .report_test_hash
        .keys
        .each do |index|
          it "returns the #{
               index
             } that matches the test data for the 1st row" do
            expect(exported_data[0][index.to_sym]).to eq(expected_values[index])
          end
        end
    end
  end
end
