describe UseCase::ExportOpenDataDec do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release " do
    describe "for the DEC and reports" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:dec_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec") }
      let(:dec_assessment_id) { dec_xml.at("RRN") }
      let(:dec_assessment_date) { dec_xml.at("Registration-Date") }

      let(:date_today) { DateTime.now.strftime("%F") }
      let(:time_today) { DateTime.now.strftime("%F %H:%M:%S") }
      let(:number_assessments_to_test) { 2 }
      let(:expected_values) do
        Samples::ViewModels::Dec.report_test_hash.merge(
          { lodgement_date: date_today, lodgement_datetime: time_today, },
          )
      end
      let(:expected_values_1) do
        Samples::ViewModels::Dec.report_test_hash.merge(
          { lodgement_date: date_today, lodgement_datetime: DateTime.now.strftime("%F %H:%M:%S"), rrn: "0000-0000-0000-0000-0001"},
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

        dec_assessment_id.children = "0000-0000-0000-0000-0001"
        lodge_assessment(
          assessment_body: dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
          schema_name: "CEPC-8.0.0",
          )

      end


      # @TODO once tests have completed refactor to write one assertion for each row and compare to hash rather than for each column
      it "returns the correct number of assessments in the Data" do
        expect(exported_data.length).to eq(number_assessments_to_test)
      end

      # 1st row to test
      # write at test for each key in test hash
      Samples::ViewModels::Dec
        .report_test_hash
        .keys
        .each do |index|
        xit "returns the #{
          index
        } that matches the test data for the 1st row" do
          expect(exported_data[0][index.to_sym]).to eq(expected_values[index],)
        end
      end

      # 1st row to test
      # write at test for each key in test hash
      Samples::ViewModels::Dec
        .report_test_hash
        .keys
        .each do |index|
        xit "returns the #{
          index
        } that matches the test data for the 2nd row" do
          expect(exported_data[1][index.to_sym]).to eq(expected_values_1[index],)
        end
      end


    end
  end
end
