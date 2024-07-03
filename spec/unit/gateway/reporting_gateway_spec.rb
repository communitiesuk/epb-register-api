describe Gateway::ReportingGateway, :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  scheme_id = nil

  before(:all) do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)
  end

  before do
    add_countries
  end

  context "when extracting data from the reporting gateway" do
    subject(:gateway) { described_class.new }

    context "with certificates indicated not for publication" do
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
          call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
          xml.at("RRN").children = "0000-0000-0000-0000-0001"
          call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
          xml.at("RRN").children = "0000-0000-0000-0000-0002"
          call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
          xml.at("RRN").children = "0000-0000-0000-0000-0003"
          call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
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
          call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: cepc_xml, migrated: true)

          cepc_xml.at("//CEPC:RRN").children = "0000-0000-0000-0000-0002"
          call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: cepc_xml, migrated: true)

          dec_xml.at("RRN").children = "0000-0000-0000-0000-0003"
          call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: dec_xml, migrated: true)

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
          call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: ac_cert_xml, migrated: true)
          opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

          rdsap_schema = "RdSAP-Schema-20.0.0"
          rdsap_xml = Nokogiri.XML Samples.xml(rdsap_schema)
          rdsap_xml.at("RRN").children = "0000-0000-0000-0000-0002"
          call_lodge_assessment(scheme_id:, schema_name: rdsap_schema, xml_document: rdsap_xml, migrated: true)
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
          call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: dec_rr_xml, migrated: true)
          opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

          sap_schema = "SAP-Schema-18.0.0"
          sap_xml = Nokogiri.XML Samples.xml(sap_schema)
          sap_xml.at("RRN").children = "0000-0000-0000-0000-0003"
          call_lodge_assessment(scheme_id:, schema_name: sap_schema, xml_document: sap_xml, migrated: true)
          opt_out_assessment(assessment_id: "0000-0000-0000-0000-0003")
        end

        it "does not return the DEC-RR" do
          expect(gateway.fetch_not_for_publication_assessments.count).to eq(1)
        end
      end
    end

    context "with OD certificates exported by hashed assessment id" do
      context "when inserting four RdSAP assessments and a CEPC, opting out one of them, cancelling one and marking one not for issue" do
        let(:assessment_gateway) { Gateway::AssessmentsGateway.new }
        let(:expected_data) do
          [{ "assessment_id" => "0000-0000-0000-0000-0000",
             "created_at" => Time.utc(2021, 6, 21),
             "date_registered" => Time.utc(2020, 5, 4),
             "outcode_region" => nil,
             "postcode_region" => "Whitbury",
             "country" => "England" }]
        end

        assessment2 = %w[0000-0000-0000-0000-0002]
        assessment3 = %w[0000-0000-0000-0000-0003]
        cancelled = "cancelled_at"
        not_for_issue = "not_for_issue_at"
        time = "2021-03-26 10:53:18 +0000"

        before do
          schema = "RdSAP-Schema-20.0.0"
          xml = Nokogiri.XML Samples.xml(schema)
          call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
          xml.at("RRN").children = "0000-0000-0000-0000-0001"
          call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
          xml.at("RRN").children = "0000-0000-0000-0000-0002"
          call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
          xml.at("RRN").children = "0000-0000-0000-0000-0003"
          call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
          opt_out_assessment(assessment_id: "0000-0000-0000-0000-0001")

          commercial_schema = "CEPC-8.0.0"
          cepc_xml = Nokogiri.XML(Samples.xml(commercial_schema, "cepc"))
          cepc_xml.at("//CEPC:RRN").children = "0000-0000-0000-0000-0005"
          call_lodge_assessment(scheme_id:, schema_name: commercial_schema, xml_document: cepc_xml, migrated: true)

          assessment_gateway.update_statuses(assessment2, cancelled, time)
          assessment_gateway.update_statuses(assessment3, not_for_issue, time)

          add_postcodes("A0 0AA", 51.5045, 0.0865, "Whitbury")
          add_outcodes("A0", 51.5045, 0.4865, "Whitbury")
          add_countries
          add_assessment_country_ids
        end

        it "returns the valid Domestic certificates only" do
          returned_data = gateway.assessments_for_open_data_by_hashed_assessment_id(%w[4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a 55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4 a6f818e3dd0ac70cbd2838cb0efe0b4aadf5b43ed33a6e7cd13cb9738dca5f60 427ad45e88b1183572234b464ba07b37348243d120db1c478da42eda435e48e4 5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6 77d064b382ba8a59bde1ad0ef786f4e0c03239ca43b9d983b3ede41fc2129d45], %w[RdSAP SAP])
          expect(returned_data).to eq(expected_data)
        end
      end
    end
  end
end
