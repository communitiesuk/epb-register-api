describe Gateway::FetchAssessmentsToLinkGateway do
  include RSpecRegisterApiServiceMixin
  let(:gateway) { described_class.new }

  context "when fetching non-domestic assessments for linking" do
    before do
      insert_into_address_base("000000000001", "SW1A 2AA", "1 Commercial Street", "", "", "E")
      insert_into_address_base("000000000012", "SW1A 2AA", "4 Commercial Street", "", "", "E")
      insert_into_address_base("000000000016", "SW1A 2AA", "Some Unit", "", "", "E")

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
      # add an assessment which is linked to one of the others but has a different address line
      cepc_xml_7 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_7.at("//CEPC:RRN").content = "0000-0000-0000-0000-0007"
      cepc_xml_7.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "Unit 1 Commercial Street" }
      cepc_xml_7.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: cepc_xml_7.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      # add a group of assessments to be linked but one has an address_id in another group
      cepc_xml_8 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_8.at("//CEPC:RRN").content = "0000-0000-0000-0000-0008"
      cepc_xml_8.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "23 Sunny Avenue" }
      cepc_xml_8.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0003"
      lodge_assessment(
        assessment_body: cepc_xml_8.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      cepc_xml_9 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_9.at("//CEPC:RRN").content = "0000-0000-0000-0000-0009"
      cepc_xml_9.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "23 Sunny Avenue" }
      cepc_xml_9.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0009"
      lodge_assessment(
        assessment_body: cepc_xml_9.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      cepc_xml_10 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_10.at("//CEPC:RRN").content = "0000-0000-0000-0000-0010"
      cepc_xml_10.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1.4 commercial street" }
      cepc_xml_10.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0010"
      lodge_assessment(
        assessment_body: cepc_xml_10.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      # Does not fetch assessments when the team has already manually updated all assessments
      cepc_xml_13 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_13.at("//CEPC:RRN").content = "0000-0000-0000-0000-0013"
      cepc_xml_13.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "2 Commercial Street" }
      cepc_xml_13.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0013"
      lodge_assessment(
        assessment_body: cepc_xml_13.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      cepc_xml_14 = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml_14.at("//CEPC:RRN").content = "0000-0000-0000-0000-0014"
      cepc_xml_14.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "2 Commercial Street" }
      cepc_xml_14.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0014"
      lodge_assessment(
        assessment_body: cepc_xml_14.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
      # To provide an example of a group where all the address_ids have been updated by the epb team
      ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id SET source = 'epb_team_update' WHERE assessment_id IN ('0000-0000-0000-0000-0013', '0000-0000-0000-0000-0014') ")
      # To provide an example of a group where only one of the address_ids have been updated by the epb team
      ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id SET source = 'epb_team_update' WHERE assessment_id = '0000-0000-0000-0000-0000' ")
      gateway.drop_temp_table
      gateway.create_and_populate_temp_table
    end

    describe "#create_and_populate_temp_table" do
      it "creates a temporary table with the expected columns", :aggregate_failures do
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.table_exists?).to be(true)
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.column_names).to eq(%w[address postcode assessment_id address_id source group_id])
      end

      it "populates the temp table with assessments with the same address name, removing punctuation that come after numbers and not between numbers", :aggregate_failures do
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.count).to eq(10)
        data = Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.pluck(:assessment_id).sort
        expect(data).to eq(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002 0000-0000-0000-0000-0003 0000-0000-0000-0000-0004 0000-0000-0000-0000-0008 0000-0000-0000-0000-0009 0000-0000-0000-0000-0012 0000-0000-0000-0000-0013 0000-0000-0000-0000-0014])
      end

      it "does not fetch correctly linked assessments" do
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.pluck(:assessment_id)).not_to include("0000-0000-0000-0000-0005", "0000-0000-0000-0000-0006", "1111-0000-0000-0000-0000", "1111-0000-0000-0000-0001")
      end

      it "assign a group_id to assessments with matching addresses and postcodes", :aggregate_failures do
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "1 commercial street 2 lonely street some area some county", postcode: "SW1A 2AA").pluck(:group_id).uniq.length).to eq 1
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "1 commercial street 2 lonely street some area some county", postcode: "SW1A 2AA").pluck(:group_id).length).to eq 4

        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "14 commercial street 2 lonely street some area some county", postcode: "SW1A 2AA").pluck(:group_id).uniq.length).to eq 1
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "14 commercial street 2 lonely street some area some county", postcode: "SW1A 2AA").pluck(:group_id).length).to eq 2
      end

      it "does not fetch the address 1.4 commercial street, with punctuation between numbers" do
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(assessment_id: "0000-0000-0000-0000-0010")).not_to exist
      end
    end

    describe "#fetch_assessments_by_group_id" do
      it "return assessment id, address, id, and date registered with the same address_id found within the group" do
        group_id = Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address: "1 commercial street 2 lonely street some area some county", postcode: "SW1A 2AA").pluck(:group_id).uniq[0]
        expected_result = [
          { "assessment_id" => "0000-0000-0000-0000-0012", "address_id" => "RRN-0000-0000-0000-0000-0012", "date_registered" => Time.utc(2020, 0o5, 20), "source" => "lodgement" },
          { "assessment_id" => "0000-0000-0000-0000-0000", "address_id" => "UPRN-000000000001", "date_registered" => Time.utc(2020, 0o5, 0o4), "source" => "epb_team_update" },
          { "assessment_id" => "0000-0000-0000-0000-0001", "address_id" => "UPRN-000000000001", "date_registered" => Time.utc(2020, 0o5, 0o5), "source" => "lodgement" },
          { "assessment_id" => "0000-0000-0000-0000-0002", "address_id" => "RRN-0000-0000-0000-0000-0002", "date_registered" => Time.utc(2020, 0o5, 0o4), "source" => "lodgement" },
          { "assessment_id" => "0000-0000-0000-0000-0007", "address_id" => "RRN-0000-0000-0000-0000-0002", "date_registered" => Time.utc(2020, 0o5, 0o4), "source" => "lodgement" },
        ]
        result = gateway.fetch_assessments_by_group_id(group_id)
        expect(expected_result - result.data).to eq []
      end

      context "when it is unable to fetch data" do
        it "raises an error" do
          out_of_range_id = 10
          expect { gateway.fetch_assessments_by_group_id(out_of_range_id) }.to raise_error Boundary::NoData
        end
      end
    end

    describe "#get_max_group_id" do
      it "returns the largest group_id number" do
        expect(gateway.get_max_group_id).to eq 4
      end
    end

    describe "#fetch_groups_to_skip" do
      let(:result) { gateway.fetch_groups_to_skip }

      it "returns an array containing the group ids which either have an address_id found in more than one group, or all address_ids have been manually updated" do
        expected_duplicate_group_ids = Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address_id: "RRN-0000-0000-0000-0000-0003").pluck(:group_id)
        expected_manually_updated_group_ids = Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address_id: "RRN-0000-0000-0000-0000-0013").pluck(:group_id)
        expect((expected_duplicate_group_ids + expected_manually_updated_group_ids) - result).to eq []
      end

      it "does not return groups where only one of the address_ids in a group have been updated manually by the epb team" do
        group_with_one_updated_address_id = Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.where(address_id: "RRN-0000-0000-0000-0000-0000").pluck(:group_id)
        expect(result.include?(group_with_one_updated_address_id)).to be false
      end
    end
  end

  context "when there are no non-domestic assessments for linking" do
    let(:gateway) { described_class.new }

    before do
      gateway.drop_temp_table
      gateway.create_and_populate_temp_table
    end

    after do
      described_class.new.drop_temp_table
    end

    describe "#create_and_populate_temp_table" do
      it "does not raise an error if there is no data", :aggregate_failures do
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.table_exists?).to be(true)
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.column_names).to eq(%w[address postcode assessment_id address_id source group_id])
        expect(Gateway::FetchAssessmentsToLinkGateway::TempLinkingTable.count).to eq(0)
      end
    end

    describe "#get_max_group_id" do
      it "returns nil" do
        expect(gateway.get_max_group_id).to be_nil
      end
    end
  end
end
