describe UseCase::ExportOpenDataDomestic do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the domestic certificates and reports" do
      let(:date_today) { DateTime.now.strftime("%F") }
      let(:expected_index_0) do
        Samples::ViewModels::RdSap.report_test_hash.merge({ assessment_id: "0000-0000-0000-0000-0001", lodgement_date: date_today})
      end
      let(:expectation) { Samples::ViewModels::RdSap.report_test_hash }
      let(:exported_data) do
        described_class.new.execute({ number_of_assessments: "3", max_runs: "3", batch: "3" }).sort_by do |key|
          key["assessment_id"]
          # execute and order by assessment_id for test
        end
      end

      before(:all) do

        scheme_id = add_scheme_and_get_id
        domestic_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        domestic_assessment_id = domestic_xml.at("RRN")
        domestic_assessment_date = domestic_xml.at("Registration-Date")

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")
        domestic_sap_assessment_date = domestic_sap_xml.at("Registration-Date")
        domestic_sap_assessment_level = domestic_sap_xml.at("Level")

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
        domestic_assessment_date.children = "2017-05-04"
        domestic_assessment_id.children = "0000-0000-0000-0000-0100"
        lodge_assessment(
          assessment_body: domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
        )

        domestic_assessment_date.children = "2019-07-02"
        domestic_assessment_id.children = "0000-0000-0000-0000-0000"
        lodge_assessment(
          assessment_body: domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
        )

        domestic_sap_assessment_date.children = "2020-05-04"
        domestic_sap_assessment_id.children = "0000-0000-0000-0000-1000"
        domestic_sap_assessment_level.children = "3"
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
        )
      end

      it "expects the number of valid RdSAP lodgements for ODC to be 1" do
        expect(exported_data.length).to eq(1)
      end

      # Samples::ViewModels::RdSap
      #   .report_test_hash
      #   .keys
      #   .each do |index|
      #   it "returns the #{index} that matches the test data for the 0th index" do
      #     expect(exported_data[0][index.to_sym]).to eq(expected_index_0[index])
      #     end
      #   end
    end
  end
end
