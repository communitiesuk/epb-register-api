describe Gateway::FetchAssessmentsToLinkGateway do
  include RSpecRegisterApiServiceMixin

  let(:gateway) { described_class.new }

  describe "#fetch_assessments" do
    before do
      insert_into_address_base("000000000001", "A0 0AA", "1 Commercial Street", "", "", "E")
      insert_into_address_base("000000000012", "A0 0AA", "4 Commercial Street", "", "", "E")
      insert_into_address_base("000000000016", "A0 0AA", "Some Unit", "", "", "E")

      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id:)

      cepc_xml_1 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc+rr")
      cepc_xml_1.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Commercial Street" }
      lodge_assessment(
        assessment_body: cepc_xml_1.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      cepc_xml_2 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_2.at("//CEPC:RRN").content = "0000-0000-0000-0000-0002"
      cepc_xml_2.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Commercial Street" }
      cepc_xml_2.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: cepc_xml_2.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      ac_cert_xml_1 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "ac-cert")
      ac_cert_xml_1.at("RRN").content = "0000-0000-0000-0000-0012"
      ac_cert_xml_1.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1, Commercial Street" }
      ac_cert_xml_1.at("UPRN").content = "RRN-0000-0000-0000-0000-0012"
      lodge_assessment(
        assessment_body: ac_cert_xml_1.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      cepc_xml_3 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_3.at("//CEPC:RRN").content = "0000-0000-0000-0000-0003"
      cepc_xml_3.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "14 Commercial Street" }
      cepc_xml_3.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0003"
      lodge_assessment(
        assessment_body: cepc_xml_3.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      cepc_xml_4 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_4.at("//CEPC:RRN").content = "0000-0000-0000-0000-0004"
      cepc_xml_4.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "14 Commercial Street" }
      cepc_xml_4.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0004"
      lodge_assessment(
        assessment_body: cepc_xml_4.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      cepc_xml_5 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_5.at("//CEPC:RRN").content = "0000-0000-0000-0000-0005"
      cepc_xml_5.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "4 Commercial Street" }
      cepc_xml_5.at("//CEPC:UPRN").content = "UPRN-000000000012"
      lodge_assessment(
        assessment_body: cepc_xml_5.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      cepc_xml_6 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_6.at("//CEPC:RRN").content = "0000-0000-0000-0000-0006"
      cepc_xml_6.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "4 Commercial Street" }
      cepc_xml_6.at("//CEPC:UPRN").content = "UPRN-000000000012"
      lodge_assessment(
        assessment_body: cepc_xml_6.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      dec_plus_rr_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec+rr")
      dec_plus_rr_xml
        .xpath("//*[local-name() = 'UPRN']")
        .each do |node|
        node.content = "UPRN-000000000016"
      end
      dec_plus_rr_xml
        .xpath("//*[local-name() = 'RRN']")
        .each_with_index do |node, index|
        node.content = "1111-0000-0000-0000-000#{index}"
      end
      dec_plus_rr_xml
        .xpath("//*[local-name() = 'Related-RRN']")
        .reverse
        .each_with_index do |node, index|
        node.content = "1111-0000-0000-0000-000#{index}"
      end

      lodge_assessment(
        assessment_body: dec_plus_rr_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
    end

    it "fetches all assessments with the same address name, including those that vary by only punctuation" do
      result = gateway.fetch_assessments
      expect(result.count).to eq 6
      expect(result.columns).to eq %w[address postcode assessment_id address_id date_registered]
      expect(result.rows.to_s).to include("0000-0000-0000-0000-0000", "0000-0000-0000-0000-0001", "0000-0000-0000-0000-0012", "0000-0000-0000-0000-0002", "0000-0000-0000-0000-0003", "0000-0000-0000-0000-0004")
    end

    it "does not fetch correctly linked assessments" do
      result = gateway.fetch_assessments
      expect(result.rows.to_s).not_to include("0000-0000-0000-0000-0005", "0000-0000-0000-0000-0006", "1111-0000-0000-0000-0000", "1111-0000-0000-0000-0001")
    end
  end
end
