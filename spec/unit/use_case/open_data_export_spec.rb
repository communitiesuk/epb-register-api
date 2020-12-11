describe UseCase::OpenDataExport do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the domestic certificates and reports" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:domestic_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
      let(:domestic_assessment_id) { domestic_xml.at("RRN") }
      let(:domestic_assessment_date) { domestic_xml.at("Registration-Date") }

      let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
      let(:non_domestic_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }
      let(:non_domestic_assessment_date) { non_domestic_xml.at("//CEPC:Registration-Date") }

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
        domestic_assessment_date.children = "2017-05-04"
        lodge_assessment(
            assessment_body: domestic_xml.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            override: true,
            )

        domestic_assessment_date.children = "2018-05-04"
        domestic_assessment_id.children = "0000-0000-0000-0000-0001"
        lodge_assessment(
            assessment_body: domestic_xml.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            override: true,
            )

        non_domestic_assessment_date.children = "2019-05-04"
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
        response = open_data_export.execute({ number_of_assessments: '3', max_runs: '3', batch: '3' })

        expect(response[0]).to eq <<~CSV
            type_of_assessment,assessment_id,date_of_expiry,report_type,date_of_assessment,date_of_registration,address_id,address_line1,address_line2,address_line3,address_line4,town,postcode,scheme_assessor_id
            RdSAP,0000-0000-0000-0000-0000,2027-05-03,,2020-05-04,2017-05-04,RRN-0000-0000-0000-0000-0000,1 Some Street,"","","",Post-Town1,A0 0AA,SPEC000000
            RdSAP,0000-0000-0000-0000-0001,2028-05-03,,2020-05-04,2018-05-04,RRN-0000-0000-0000-0000-0001,1 Some Street,"","","",Post-Town1,A0 0AA,SPEC000000
            CEPC,0000-0000-0000-0000-0002,2026-05-04,3,2020-05-04,2019-05-04,RRN-0000-0000-0000-0000-0002,2 Lonely Street,,,,Post-Town1,A0 0AA,SPEC000000
          CSV
      end
    end
  end
end
