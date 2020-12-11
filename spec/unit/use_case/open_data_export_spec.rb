describe UseCase::OpenDataExport do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the domestic certificates and reports" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:domestic_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
      let(:domestic_assessment_id) { domestic_xml.at("RRN") }

      let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
      let(:non_domestic_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }

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
            assessment_body: domestic_xml.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            override: true,
            )

        domestic_assessment_id.children = "0000-0000-0000-0000-0001"
        lodge_assessment(
            assessment_body: domestic_xml.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            override: true,
            )

        non_domestic_assessment_id.children = "0000-0000-0000-0000-0002"
        lodge_assessment(
            assessment_body: non_domestic_xml.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-8.0.0",
            )
      end

      it "populates the database with the expected values" do

        open_data_export = described_class.new
        response = open_data_export.execute({ number_of_assessments: '3', max_runs: '3', batch: '2' })

        expect(response).to eq "CEPC,0000-0000-0000-0000-0002,2026-05-04,3,2020-05-04,2020-05-04,RRN-0000-0000-0000-0000-0002,2 Lonely Street,,,,Post-Town1,A0 0AA,SPEC000000\n"
      end
    end
  end
end
