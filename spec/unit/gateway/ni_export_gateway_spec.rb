describe Gateway::NiExportGateway do

  include RSpecRegisterApiServiceMixin

  subject{ described_class.new }

  context "when extracting Northern Ireland data for export " do

    it 'call the gateway without error' do
      expect{ subject}.not_to raise_error
    end

    describe '.fetch_assessments' do

      before(:all) do
        scheme_id = add_scheme_and_get_id
        add_super_assessor(scheme_id)

        domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
        domestic_ni_sap_assessment_id = domestic_ni_sap_xml.at("RRN")

        domestic_ni_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-NI-20.0.0")
        domestic_ni_rdsap_assessment_id = domestic_ni_rdsap_xml.at("RRN")

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")

        domestic_ni_sap_postcode = domestic_ni_sap_xml.at("Property Address Postcode")
        domestic_ni_rdsap_postcode = domestic_ni_rdsap_xml.at("Property Address Postcode")
        domestic_ni_sap_postcode.children = "BT4 3NE"
        domestic_ni_rdsap_postcode.children = "BT1 3NE"

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
        domestic_sap_postcode = domestic_sap_xml.at("Property Address Postcode")
        domestic_sap_postcode = "BT0 2SA"
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
          )
      end

      let!(:exported_data){
        subject.fetch_assessments(%w[RdSAP SAP])
      }

      let(:expectation){
        [{"assessment_id" => "0000-0000-0000-0000-0000"},
         {"assessment_id" => "0000-0000-0000-0000-0002"}
        ]
      }

      it 'exports only lodged certificates that have a BT postcode and a NI schema' do
         expect(exported_data).to eq(expectation)
    end

  end
  end
end
