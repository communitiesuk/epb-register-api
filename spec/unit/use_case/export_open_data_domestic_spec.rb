describe UseCase::ExportOpenDataDomestic do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the domestic certificates and reports" do
      let(:rdsap_odc_hash) do
        Samples::ViewModels::RdSap.report_test_hash.merge(
          {
            rrn: "0000-0000-0000-0000-0000",
            lodgement_date: date_today,
          },
        )
      end
      let(:sap_odc_hash) do
        Samples::ViewModels::Sap.report_test_hash.merge(
          {
            rrn: "0000-0000-0000-0000-1000",
            lodgement_date: date_today,
          },
          )
      end
      let(:exported_data) { described_class.new.execute }

      before(:all) do
        scheme_id = add_scheme_and_get_id
        domestic_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        domestic_assessment_id = domestic_xml.at("RRN")
        domestic_assessment_date = domestic_xml.at("Registration-Date")

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")
        domestic_sap_assessment_date = domestic_sap_xml.at("Registration-Date")

        domestic_legacy_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-17.0")
        domestic_legacy_sap_assessment_id = domestic_legacy_sap_xml.at("RRN")
        domestic_legacy_sap_assessment_date = domestic_legacy_sap_xml.at("Registration-Date")

        domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
        domestic_ni_sap_assessment_id = domestic_ni_sap_xml.at("RRN")
        domestic_ni_sap_assessment_date = domestic_ni_sap_xml.at("Registration-Date")

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
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        domestic_assessment_date.children = date_today
        domestic_assessment_id.children = "0000-0000-0000-0000-0000"
        lodge_assessment(
          assessment_body: domestic_xml.to_xml,
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
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-17.0",
          override: true,
        )

     end

      it "expects the number of non Northern Irish RdSAP and SAP lodgements within required date range for ODC to be 2" do
        expect(exported_data.length).to eq(2)
      end

      Samples::ViewModels::RdSap
        .report_test_hash
        .keys
        .each do |key|
        it "returns the #{key} that matches the RdSAP test data for the equivalent entry in the ODC hash" do
          expect(exported_data[0][key.to_sym]).to include(rdsap_odc_hash[key])
        end
      end

      Samples::ViewModels::Sap
        .report_test_hash
        .reject { |k| %i[flat_storey_count unheated_corridor_length mains_gas_flag heat_loss_corridor number_heated_rooms number_habitable_rooms photo_supply glazed_area].include? k }
        .keys
        .each do |key|
        it "returns the #{key} that matches the SAP test data for the equivalent entry in the ODC hash" do
          expect(exported_data[1][key.to_sym]).to include(sap_odc_hash[key])
        end
      end
    end
  end
end
