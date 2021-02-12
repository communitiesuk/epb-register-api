describe UseCase::ExportOpenDataDomesticrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data domestic recommendations report release" do
    describe "for the domestic recommendation report" do
      let(:exported_data) { described_class.new.execute("2019-07-01") }

      before(:all) do
        scheme_id = add_scheme_and_get_id
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        domestic_rdsap_assessment_id = domestic_rdsap_xml.at("RRN")
        domestic_rdsap_assessment_date =
          domestic_rdsap_xml.at("Registration-Date")

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")
        domestic_sap_assessment_date = domestic_sap_xml.at("Registration-Date")

        domestic_legacy_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-17.0")
        domestic_legacy_sap_assessment_id = domestic_legacy_sap_xml.at("RRN")
        domestic_legacy_sap_assessment_date =
          domestic_legacy_sap_xml.at("Registration-Date")

        domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
        domestic_ni_sap_assessment_id = domestic_ni_sap_xml.at("RRN")
        domestic_ni_sap_assessment_date =
          domestic_ni_sap_xml.at("Registration-Date")

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

        domestic_rdsap_assessment_date.children = "2017-05-04"
        domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0100"
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        domestic_rdsap_assessment_date.children = date_today
        domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0000"
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        # TODO: Add NI lodgement

        domestic_sap_assessment_date.children = date_today
        domestic_sap_assessment_id.children = "0000-0000-0000-0000-1000"
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
        )

        domestic_legacy_sap_assessment_date.children = "2017-05-04"
        domestic_legacy_sap_assessment_id.children = "0000-0000-0000-0000-1010"
        lodge_assessment(
          assessment_body: domestic_legacy_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-17.0",
          override: true,
        )
      end

      it "returns the correct number of assessments excluding the NI lodgements and any before the given date" do
        expect(exported_data.length).to eq(2)
      end

      it "returns the correct number of recommendations for each assessment" do
        expect(exported_data.first[:recommendations].length).to eq(2)
        expect(exported_data.last[:recommendations].length).to eq(2)
      end

      it "returns recommendations in the following format" do
        expect(exported_data[0]).to eq(
            {
              recommendations: [
                {
                  assessment_id: "0000-0000-0000-0000-0000",
                  improvement_code: "5",
                  improvement_description: nil,
                  improvement_summary: nil,
                  indicative_cost: "£100 - £350",
                  sequence: 1,
                },
                {
                  assessment_id: "0000-0000-0000-0000-0000",
                  improvement_code: "1",
                  improvement_description: nil,
                  improvement_summary: nil,
                  indicative_cost: "2000",
                  sequence: 2,
                },
              ],
            },
        )
      end
    end
  end
end
