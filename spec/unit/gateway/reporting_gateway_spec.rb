describe Gateway::ReportingGateway do
  include RSpecRegisterApiServiceMixin

  scheme_id = nil

  before(:all) do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)
  end

  context "when extracting data from the reporting gateway" do
    subject(:gateway) { described_class.new }

    context "when inserting four RdSAP assessments, opting out one of them, cancelling one and marking one not for issue" do
      let(:assessment_gateway) { Gateway::AssessmentsGateway.new }
      let(:expected_data) do
        [{
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
        }]
      end
      let(:selected_data) do
        subject.fetch_not_for_publication_assessments.select { |n| n["assessment_id"] == "0000-0000-0000-0000-0001" }
      end

      assessment2 = %w[0000-0000-0000-0000-0002]
      assessment3 = %w[0000-0000-0000-0000-0003]
      cancelled = "cancelled_at"
      not_for_issue = "not_for_issue_at"
      time = "2021-03-26 10:53:18 +0000"

      before do
        schema = "RdSAP-Schema-20.0.0"
        xml = Nokogiri.XML Samples.xml(schema)
        call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml)
        xml.at("RRN").children = "0000-0000-0000-0000-0001"
        call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml)
        xml.at("RRN").children = "0000-0000-0000-0000-0002"
        call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml)
        xml.at("RRN").children = "0000-0000-0000-0000-0003"
        call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml)
        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0001")
        assessment_gateway.update_statuses(assessment2, cancelled, time)
        assessment_gateway.update_statuses(assessment3, not_for_issue, time)
      end

      it "returns the opted out assessments only" do
        expect(gateway.fetch_not_for_publication_assessments.count).to eq(3)
        expect(selected_data).to eq(expected_data)
      end
    end

    context "when inserting 2 CEPC & DEC and opting out one CEPC and DEC" do
      let(:expected_data) do
        [{
          "assessment_id" => "0000-0000-0000-0000-0003",
          "type_of_assessment" => "DEC",
          "address_line1" => "Some Unit",
          "address_line2" => "2 Lonely Street",
          "address_line3" => "Some Area",
          "town" => "Whitbury",
          "postcode" => "A0 0AA",
          "date_registered" => "2020-05-04",
          "address_id" => "UPRN-000000000001",
          "not_for_issue_at" => nil,
          "opt_out" => true,
          "cancelled_at" => nil,
        }]
      end

      let(:selected_data) do
        subject.fetch_not_for_publication_assessments.select { |n| n["assessment_id"] == "0000-0000-0000-0000-0003" }
      end

      before do
        commercial_schema = "CEPC-8.0.0"
        cepc_xml = Nokogiri.XML(Samples.xml(commercial_schema, "cepc"))
        dec_xml = Nokogiri.XML Samples.xml(commercial_schema, "dec")

        cepc_xml.at("//CEPC:RRN").children = "0000-0000-0000-0000-0001"
        call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: cepc_xml)

        cepc_xml.at("//CEPC:RRN").children = "0000-0000-0000-0000-0002"
        call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: cepc_xml)

        dec_xml.at("RRN").children = "0000-0000-0000-0000-0003"
        call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: dec_xml)

        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0001")
        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0003")
      end

      it "returns only 1 SAP and the DEC" do
        expect(gateway.fetch_not_for_publication_assessments.count).to eq(2)
        expect(selected_data).to eq(expected_data)
      end
    end

    context "when inserting RdSAP, AC-CERT and opting out the RdSAP" do
      before do
        commercial_schema = "CEPC-8.0.0"
        ac_cert_xml = Nokogiri.XML Samples.xml(commercial_schema, "ac-cert")
        call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: ac_cert_xml)
        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

        rdsap_schema = "RdSAP-Schema-20.0.0"
        rdsap_xml = Nokogiri.XML Samples.xml(rdsap_schema)
        rdsap_xml.at("RRN").children = "0000-0000-0000-0000-0002"
        call_lodge_assessment(scheme_id:, schema_name: rdsap_schema, xml_document: rdsap_xml)
        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0002")
      end

      it "does not return the AC-CERT" do
        expect(gateway.fetch_not_for_publication_assessments.count).to eq(1)
      end
    end

    context "when inserting SAP, DEC-RR and opting out the SAP" do
      before do
        commercial_schema = "CEPC-8.0.0"
        dec_rr_xml = Nokogiri.XML Samples.xml(commercial_schema, "dec-rr")
        call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: dec_rr_xml)
        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

        sap_schema = "SAP-Schema-18.0.0"
        sap_xml = Nokogiri.XML Samples.xml(sap_schema)
        sap_xml.at("RRN").children = "0000-0000-0000-0000-0003"
        call_lodge_assessment(scheme_id:, schema_name: sap_schema, xml_document: sap_xml)
        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0003")
      end

      it "does not return the DEC-RR" do
        expect(gateway.fetch_not_for_publication_assessments.count).to eq(1)
      end
    end
  end
end
