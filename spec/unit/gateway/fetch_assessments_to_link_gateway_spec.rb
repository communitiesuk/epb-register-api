describe Gateway::FetchAssessmentsToLinkGateway do
  include RSpecRegisterApiServiceMixin

  before(:all) do
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
    # fetches with additional punctuation
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
    # does not fetch correctly linked assessments
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
    cepc_xml_6.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "4, Commercial Street" }
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
    # does not fetch correctly linked assessments
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

    described_class.new.create_and_populate_temp_table
  end

  describe "#create_and_populate_temp_table" do
    it "creates a temporary table with the expected columns", aggregate_failures: true  do
      expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.table_exists?).to be(true)
      expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.column_names).to eq(%w[address postcode assessment_id address_id date_registered group_id])
    end

    it "populates the temporary table with assessments with the same address name, including those that vary only by punctuation", aggregate_failures: true do
      expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.count).to eq(6)
      data = Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.pluck(:assessment_id).sort
      expect(data).to eq(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002 0000-0000-0000-0000-0003 0000-0000-0000-0000-0004 0000-0000-0000-0000-0012])
    end

    it "does not fetch correctly linked assessments" do
      expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.pluck(:assessment_id)).not_to include("0000-0000-0000-0000-0005", "0000-0000-0000-0000-0006", "1111-0000-0000-0000-0000", "1111-0000-0000-0000-0001")
    end

    it "assign a group_id to assessments with matching addresses and postcodes", aggregate_failures: true do
      expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "1 commercial street 2 lonely street some area some county", postcode: "A0 0AA").pluck(:group_id).uniq.length).to eq 1
      expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "1 commercial street 2 lonely street some area some county", postcode: "A0 0AA").pluck(:group_id).length).to eq 4

      expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "14 commercial street 2 lonely street some area some county", postcode: "A0 0AA").pluck(:group_id).uniq.length).to eq 1
      expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "14 commercial street 2 lonely street some area some county", postcode: "A0 0AA").pluck(:group_id).length).to eq 2
    end
  end
end
