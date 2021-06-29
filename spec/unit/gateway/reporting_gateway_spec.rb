describe "Gateway::ReportingGateway" do
  include RSpecRegisterApiServiceMixin
  context "test data extracted from the reporting gateway" do
    subject { Gateway::ReportingGateway.new }
    before(:all) do
      @scheme_id = add_scheme_and_get_id
      add_super_assessor(@scheme_id)
    end
    context "Insert four assessments and opt out one of them, cancel one and mark one not for issue" do
      let(:assessment_gateway) { Gateway::AssessmentsGateway.new }
      assessment2 = %w[0000-0000-0000-0000-0002]
      assessment3 = %w[0000-0000-0000-0000-0003]
      cancelled = "cancelled_at"
      not_for_issue = "not_for_issue_at"
      time = "2021-03-26 10:53:18 +0000"

      before do
        schema = "RdSAP-Schema-20.0.0"
        xml = Nokogiri.XML Samples.xml(schema)
        call_lodge_assessment(@scheme_id, schema, xml)
        xml.at("RRN").children = "0000-0000-0000-0000-0001"
        call_lodge_assessment(@scheme_id, schema, xml)
        xml.at("RRN").children = "0000-0000-0000-0000-0002"
        call_lodge_assessment(@scheme_id, schema, xml)
        xml.at("RRN").children = "0000-0000-0000-0000-0003"
        call_lodge_assessment(@scheme_id, schema, xml)
        opt_out_assessment("0000-0000-0000-0000-0001")
        assessment_gateway.update_statuses(assessment2, cancelled, time)
        assessment_gateway.update_statuses(assessment3, not_for_issue, time)
      end

      let(:expected_data) do
        {
          "assessment_id" => "0000-0000-0000-0000-0001",
          "type_of_assessment" => "RdSAP",
          "address_line1" => "1 Some Street",
          "address_line2" => "",
          "address_line3" => "",
          "town" => "Whitbury",
          "postcode" => "A0 0AA",
          "date_registered" => "2020-05-04",
          "address_id" => "UPRN-000000000000",
          "not_for_issue_at" => nil,
          "opt_out" => true,
          "cancelled_at" => nil,
        }
      end

      it "returns the opted out assessments only" do
        expect(subject.fetch_not_for_publication_assessments.count).to eq(3)
        expect(subject.fetch_not_for_publication_assessments[0]).to eq(expected_data)
      end
    end

    context "Insert RdSAP, AC-CERT and opt out the RdSAP" do
      before do
        commercial_schema = "CEPC-8.0.0"
        ac_cert_xml = Nokogiri.XML Samples.xml(commercial_schema, "ac-cert")
        call_lodge_assessment(@scheme_id, commercial_schema, ac_cert_xml)
        opt_out_assessment("0000-0000-0000-0000-0000")

        rdsap_schema = "RdSAP-Schema-20.0.0"
        rdsap_xml = Nokogiri.XML Samples.xml(rdsap_schema)
        rdsap_xml.at("RRN").children = "0000-0000-0000-0000-0002"
        call_lodge_assessment(@scheme_id, rdsap_schema, rdsap_xml)
        opt_out_assessment("0000-0000-0000-0000-0002")
      end

      it "does not return the AC-CERT" do
        expect(subject.fetch_not_for_publication_assessments.count).to eq(1)
      end
    end

    context "Insert SAP, DEC-RR and opt out the SAP" do
      before do
        commercial_schema = "CEPC-8.0.0"
        dec_rr_xml = Nokogiri.XML Samples.xml(commercial_schema, "dec-rr")
        call_lodge_assessment(@scheme_id, commercial_schema, dec_rr_xml)
        opt_out_assessment("0000-0000-0000-0000-0000")

        sap_schema = "SAP-Schema-18.0.0"
        sap_xml = Nokogiri.XML Samples.xml(sap_schema)
        sap_xml.at("RRN").children = "0000-0000-0000-0000-0003"
        call_lodge_assessment(@scheme_id, sap_schema, sap_xml)
        opt_out_assessment("0000-0000-0000-0000-0003")
      end

      it "does not return the DEC-RR" do
        expect(subject.fetch_not_for_publication_assessments.count).to eq(1)
      end
    end
  end
end
