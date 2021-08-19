describe Gateway::ExportNiGateway do
  include RSpecRegisterApiServiceMixin

  subject { described_class.new }



  context "when extracting Northern Ireland data for export " do
    before(:all) do
      Timecop.freeze(2021,02,22,0,0,0)
    end

    after(:all) do
      Timecop.return
    end


    it "call the gateway without error" do
      expect { subject }.not_to raise_error
    end

    describe ".fetch_assessments" do
      before(:all) do
        scheme_id = add_scheme_and_get_id
        add_super_assessor(scheme_id: scheme_id)

        domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
        domestic_ni_sap_assessment_id = domestic_ni_sap_xml.at("RRN")

        domestic_ni_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-NI-20.0.0")
        domestic_ni_rdsap_assessment_id = domestic_ni_rdsap_xml.at("RRN")

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")

        lodge_assessment(
          assessment_body: domestic_ni_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-NI-18.0.0",
          override: true,
        )

        domestic_ni_rdsap_assessment_id.children = "0000-0000-0000-0000-0002"
        lodge_assessment(
          assessment_body: domestic_ni_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-NI-20.0.0",
          override: true,
        )

        domestic_sap_assessment_id.children = "1000-0000-0000-0000-1010"

        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
        )

        non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-NI-8.0.0", "cepc")
        non_domestic_assessment_id = non_domestic_xml.at("RRN")
        non_domestic_assessment_id.children = "9000-0000-0000-0000-1019"
        non_domestic_xml_postcode = non_domestic_xml.at("Postcode")
        non_domestic_xml_postcode.children = "BT5 2SA"

        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-NI-8.0.0",
        )
      end

      let(:domestic_expectation) do
        [{ "assessment_id" => "0000-0000-0000-0000-0000",
           "lodgement_date" => '2020-05-04',
           "lodgement_datetime" => "2021-02-22 00:00:00",
           "uprn" => "UPRN-000000000000",},
           { "assessment_id" => "0000-0000-0000-0000-0002",
           "lodgement_date" => '2020-05-04',
           "lodgement_datetime" => "2021-02-22 00:00:00",
           "uprn" => "UPRN-000000000000",
         }]
      end

      let(:commercial_expectation) do
        [{"assessment_id"=>"9000-0000-0000-0000-1019",
          "lodgement_date" => '2020-05-04',
          "lodgement_datetime" => "2021-02-22 00:00:00",
          "uprn"=>"UPRN-000000000001"}]
      end

      it "exports only domestic certificates that have a BT postcode and a NI schema" do
        expect(subject.fetch_assessments(%w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }).to eq(domestic_expectation)
      end

      it "exports only commercial certificates that have a BT postcode and a NI schema" do
        expect(subject.fetch_assessments("CEPC")).to eq(commercial_expectation)
      end
    end
  end
end
