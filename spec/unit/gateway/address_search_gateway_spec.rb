shared_examples "when searching by postcode" do
  it "returns addresses from address base" do
    address = gateway.search_by_postcode("SE1 7EF", nil, nil).first.line1
    expect(address).to eq "1 McDonald Road"
  end

  context "when a postcode has addresses in address base and addresses associated with assessments not in address base" do
    let(:addresses) { gateway.search_by_postcode("SW1A 2AA", nil, nil) }

    it "returns all address_ids associated with the postcode" do
      expect(addresses.map(&:address_id)).to match_array(%w[
        RRN-0000-0000-0000-0000-0111
        UPRN-000000000000
        UPRN-000000000002
      ])
    end

    it "returns the expected existing assessments associated with the addresses on the postcode" do
      address_by_id = addresses.index_by(&:address_id)

      expect(address_by_id["RRN-0000-0000-0000-0000-0111"].existing_assessments[0]["assessmentId"])
        .to eq("0000-0000-0000-0000-0111")

      expect(address_by_id["UPRN-000000000000"].existing_assessments[0]["assessmentId"])
        .to eq("0000-0000-0000-0000-1111")

      expect(address_by_id["UPRN-000000000002"].existing_assessments)
        .to eq []
    end
  end

  context "when the address already contains an apostrophe" do
    it "returns only one address for the relevant property" do
      result = gateway.search_by_postcode("S1 0AA", "Barry's Street", nil)
      expect(result.length).to eq(1)
    end
  end

  context "when searching with a building number" do
    it "returns the most relevant address at the top of the result" do
      addresses = gateway.search_by_postcode("SW1A 2AA", "2", nil)
      expect(addresses.length).to eq 3
      expect(addresses.first.line1).to eq "2 Some Street"
      expect(addresses.first.town).to eq("LONDON")
      expect(addresses.first.postcode).to eq("SW1A 2AA")
      expect(addresses.first.address_id).to eq("UPRN-000000000002")
      expect(addresses.first.source).to eq("GAZETTEER")
    end

    context "when searching with a buildingNameNumber containing just a single quote" do
      it "does not error" do
        expect { gateway.search_by_postcode("SW1A 2AA", "'", nil) }.not_to raise_error
      end
    end
  end

  context "when an address type is passed" do
    let(:addresses) { gateway.search_by_postcode("SW1A 2AA", nil, "COMMERCIAL") }

    before do
      cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc+rr")

      # UPRN-000000000001
      lodge_assessment(
        assessment_body: cepc_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [get_scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
    end

    it "returns the addresses at the postcode" do
      expect(addresses.map(&:address_id)).to match_array(%w[
        UPRN-000000000000
        UPRN-000000000001
        UPRN-000000000002
      ])
    end

    it "returns only existing assessments which match the assessment type" do
      address_by_id = addresses.index_by(&:address_id)
      expect(address_by_id["UPRN-000000000000"].existing_assessments)
        .to eq []

      expect(address_by_id["UPRN-000000000001"].existing_assessments[0]["assessmentId"])
        .to eq("0000-0000-0000-0000-0000")

      expect(address_by_id["UPRN-000000000001"].existing_assessments[1]["assessmentId"])
        .to eq("0000-0000-0000-0000-0001")

      expect(address_by_id["UPRN-000000000002"].existing_assessments)
        .to eq []
    end
  end

  context "when an assessment has been linked through the assessments_address_ids table" do
    before do
      sap_schema = "SAP-Schema-18.0.0"
      sap_xml = Nokogiri.XML(Samples.xml(sap_schema))
      sap_xml.at("RRN").content = "0000-0000-0000-0000-0112"
      sap_xml.at_css("Property Address Address-Line-1").content = "5 Some Street"
      lodge_assessment(
        assessment_body: sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [get_scheme_id],
        },
        schema_name: sap_schema,
        migrated: true,
      )
      ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id SET address_id = 'UPRN-000000000111' WHERE assessment_id = '0000-0000-0000-0000-0112' ", "SQL")
    end

    it "returns assessment from the assessment address id table" do
      addresses = gateway.search_by_postcode("SW1A 2AA", nil, nil)
      expect(addresses.map(&:address_id)).to match_array(%w[
        RRN-0000-0000-0000-0000-0111
        UPRN-000000000000
        UPRN-000000000002
        UPRN-000000000111
      ])
    end
  end
end

shared_examples "when searching by address_id" do
  it "returns the address associated with an UPRN" do
    address = gateway.search_by_address_id("UPRN-1234123412323232").first.line1
    expect(address).to eq "1 McDonald Road"
  end

  it "returns the address associated with an address_id" do
    address = gateway.search_by_address_id("RRN-0000-0000-0000-0000-1111")
    expect(address.length).to eq 1
    expect(address.first.line1).to eq "1 Some Street"
  end

  it "returns all existing assessments associated with the address_id" do
    address = gateway.search_by_address_id("UPRN-000000000000")
    expect(address.length).to eq 1

    expected_existing_assessments = %w[0000-0000-0000-0000-1111 0000-0000-0000-0000-2222]
    existing_assessments = address.first.existing_assessments
    expect(existing_assessments.pluck("assessmentId")).to match_array(expected_existing_assessments)
  end
end

shared_examples "when searching by street and town" do
  before do
    mispelled_rrn_as_uprn_sap_xml = Nokogiri.XML(Samples.xml("SAP-Schema-18.0.0"))
    mispelled_rrn_as_uprn_sap_xml.at("RRN").content = "1110-0000-0000-0000-0111"
    mispelled_rrn_as_uprn_sap_xml.at("Property Address Address-Line-1").content = "1a Some Street"
    lodge_assessment(
      assessment_body: mispelled_rrn_as_uprn_sap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [get_scheme_id],
      },
      schema_name: "SAP-Schema-18.0.0",
      migrated: true,
    )

    ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id SET address_id = 'RRN-0000-0000-0000-0000-0111' WHERE assessment_id = '1110-0000-0000-0000-0111'", "SQL")
  end

  it "returns an address base address" do
    address = gateway.search_by_street_and_town("1 MCDONALD ROAD", "LONDON", nil)
    expect(address.first.line1).to eq "1 McDonald Road"
    expect(address.first.address_id).to eq "UPRN-123412341232"
  end

  it "return addresses not in address base" do
    addresses = gateway.search_by_street_and_town("SOME STREET", "WHITBURY", nil)
    expect(addresses.map(&:address_id)).to match_array(%w[
      RRN-0000-0000-0000-0000-0111
      UPRN-000000000000
      UPRN-000000000002
    ])
    addresses.each do |address|
      expect(address.line1).to include("Some Street")
    end
  end

  it "returns linked assessments in the existing assessments even if the address line differs slightly" do
    addresses = gateway.search_by_street_and_town("SOME STREET", "WHITBURY", nil)
    address_by_id = addresses.index_by(&:address_id)
    expect(address_by_id["RRN-0000-0000-0000-0000-0111"].line1).to eq "1 Some Street"
    expect(address_by_id["RRN-0000-0000-0000-0000-0111"].existing_assessments.length).to eq 2
    expect(address_by_id["RRN-0000-0000-0000-0000-0111"].existing_assessments[0]["assessmentId"])
      .to eq("0000-0000-0000-0000-0111")
    expect(address_by_id["RRN-0000-0000-0000-0000-0111"].existing_assessments[1]["assessmentId"])
      .to eq("1110-0000-0000-0000-0111")
  end

  context "when an address type is passed" do
    before do
      cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc+rr")

      lodge_assessment(
        assessment_body: cepc_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [get_scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
    end

    it "returns the relevant addresses when the address type is passed" do
      addresses = gateway.search_by_street_and_town("SOME UNIT", "FULCHESTER", "COMMERCIAL")
      expect(addresses.length).to eq 1
      expect(addresses.map(&:address_id)).to match_array(%w[
        UPRN-000000000001
      ])

      address_by_id = addresses.index_by(&:address_id)

      expect(address_by_id["UPRN-000000000001"].existing_assessments.length)
        .to eq 1
    end

    it "filters out the domestic addresses" do
      addresses = gateway.search_by_street_and_town("SOME STREET", "WHITBURY", "COMMERCIAL")
      expect(addresses.map(&:address_id)).to match_array(%w[
        UPRN-000000000000
        UPRN-000000000002
      ])
      addresses.each do |address|
        expect(address.line1).to include("Some Street")
      end
    end
  end
end

shared_context "when adding a scheme and assessor" do
  def get_scheme_id
    Gateway::SchemesGateway.new.all.first[:scheme_id]
  end
end

describe Gateway::AddressSearchGateway do
  subject(:gateway) { described_class.new }

  include RSpecRegisterApiServiceMixin

  context "when searching for addresses from address_base and assessments" do
    include_context "when adding a scheme and assessor"
    before(:all) do
      # scottish address
      scheme_id = add_scheme_and_get_id
      insert_into_address_base("1234123417777777", "EH1 2NG", "2 MCDONALD ROAD", "SHELDSTOWN", "BOARDERS", "S")
      # english address
      insert_into_address_base("1234123412323232", "SE1 7EF", "1 MCDONALD ROAD", "SHELDSTOWN", "LONDON", "E")
      insert_into_address_base("000000000000", "SW1A 2AA", "1 Some Street", "WHITBURY", "LONDON", "E")
      insert_into_address_base("000000000002", "SW1A 2AA", "2 Some Street", "WHITBURY", "LONDON", "E")
      # address on the border (England)
      insert_into_address_base("1122334455", "TD9 0TU", "ENGLISH HOUSE", "BORDER ROAD", "BORDER", "E")
      # address on the border (Scotland)
      insert_into_address_base("5544332211", "TD9 0TU", "SCOTTISH HOUSE", "BORDER ROAD", "BORDER", "S")
      insert_into_address_base("0019012001", "S1 0AA", "31 Barry's Street", "", "London", "E")

      add_super_assessor(scheme_id:)
      # UPRN-000000000000
      sap_schema = "SAP-Schema-18.0.0"
      sap_xml = Nokogiri.XML(Samples.xml(sap_schema))
      sap_xml.at("RRN").content = "0000-0000-0000-0000-1111"
      lodge_assessment(
        assessment_body: sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: sap_schema,
        migrated: true,
      )

      # UPRN-000000000000
      additional_sap_xml = Nokogiri.XML(Samples.xml(sap_schema))
      additional_sap_xml.at("RRN").content = "0000-0000-0000-0000-2222"
      additional_sap_xml.at("Property Address Address-Line-1").content = "1 Some Streeet"
      lodge_assessment(
        assessment_body: additional_sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: sap_schema,
        migrated: true,
      )

      rrn_as_uprn_sap_xml = Nokogiri.XML(Samples.xml(sap_schema))
      rrn_as_uprn_sap_xml.at("UPRN").content = "RRN-0000-0000-0000-0000-0111"
      rrn_as_uprn_sap_xml.at("RRN").content = "0000-0000-0000-0000-0111"
      lodge_assessment(
        assessment_body: rrn_as_uprn_sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: sap_schema,
        migrated: true,
      )

      scottish_xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-S-19.0"))
      scottish_xml.at("Property Address Address-Line-1").content = "1 Scotland Road"
      lodge_scottish_assessment(
        assessment_body: scottish_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-S-19.0",
        migrated: true,
      )
    end

    describe "#search_by_postcode" do
      context "when the toggle is off" do
        it_behaves_like "when searching by postcode"

        it "does not return addresses from Address Base that have a Scottish postcode" do
          address = gateway.search_by_postcode("EH1 2NG", nil, nil)
          expect(address).to eq []
        end

        it "does not return addresses for Scottish assessments on that postcode" do
          address = gateway.search_by_postcode("FK1 1XE", nil, nil)
          expect(address).to eq []
        end
      end

      context "when the toggle is on" do
        before do
          Helper::Toggles.set_feature("register-api-allow-scottish-address-search", true)
          cepc_xml = Nokogiri.XML Samples.xml("CEPC-S-7.1", "cepc")
          cepc_xml
            .xpath("//*[local-name() = 'RRN']")
            .each do |node|
            node.content = "0000-0000-0000-0002-0000"
          end
          lodge_scottish_assessment(
            assessment_body: cepc_xml.to_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [get_scheme_id],
            },
            schema_name: "CEPC-S-7.1",
            migrated: true,
          )
        end

        after do
          Helper::Toggles.set_feature("register-api-allow-scottish-address-search", false)
        end

        it_behaves_like "when searching by postcode"

        it "returns scottish addresses when searched by postcode" do
          address = gateway.search_by_postcode("EH1 2NG", nil, nil)
          expect(address.first.line1).to eq "2 McDonald Road"
        end

        it "returns scottish addresses when they are not in address base" do
          # LPRN-0000000000 is the address_id id this the problem
          addresses = gateway.search_by_postcode("FK1 1XE", nil, nil)
          expect(addresses.map(&:address_id)).to match_array(%w[RRN-0000-0000-0000-0000-0000 RRN-0000-0000-0000-0002-0000])
        end

        it "returns scottish and english addresses for border addresses" do
          addresses = gateway.search_by_postcode("TD9 0TU", nil, nil)
          expect(addresses.map(&:address_id)).to match_array(%w[
            UPRN-001122334455
            UPRN-005544332211
          ])
        end

        it "returns the expected assessments when selecting for assessment_type" do
          address = gateway.search_by_postcode("FK1 1XE", nil, "COMMERCIAL")
          expect(address.length).to eq 1
          expect(address[0].address_id).to eq "RRN-0000-0000-0000-0002-0000"
          expect(address[0].existing_assessments[0]["assessmentType"]).to eq "CEPC"
        end
      end
    end

    describe "#search_address_id" do
      context "when the toggle is off" do
        it_behaves_like "when searching by address_id"

        it "does not return any address for a Scottish UPRN" do
          address = gateway.search_by_address_id("UPRN-1234123417777777")
          expect(address).to eq []
        end

        it "does not return scottish addresses when they are not in address base" do
          addresses = gateway.search_by_address_id("RRN-0000-0000-0000-0000-0000")
          expect(addresses).to eq []
        end
      end

      context "when the toggle is on" do
        before do
          Helper::Toggles.set_feature("register-api-allow-scottish-address-search", true)

          # lodge scottish assessment with the same rrn as an english one
          scottish_rrn_uprn_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-S-19.0")
          scottish_rrn_uprn_xml.at("RRN").content = "0000-0000-0000-0000-0111"
          scottish_rrn_uprn_xml.at("Property Address Address-Line-1").content = "1 Scotland Street"
          lodge_scottish_assessment(
            assessment_body: scottish_rrn_uprn_xml.to_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [get_scheme_id],
            },
            schema_name: "RdSAP-Schema-S-19.0",
            migrated: true,
          )

          scottish_rrn_uprn_xml_dup = Nokogiri.XML Samples.xml("RdSAP-Schema-S-19.0")
          scottish_rrn_uprn_xml_dup.at("RRN").content = "0000-0000-0000-0000-0123"
          scottish_rrn_uprn_xml_dup.at("Property Address Address-Line-1").content = "1 Scotland Streeet"
          lodge_scottish_assessment(
            assessment_body: scottish_rrn_uprn_xml_dup.to_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [get_scheme_id],
            },
            schema_name: "RdSAP-Schema-S-19.0",
            migrated: true,
          )

          # lodge duplicate english assessment with the same rrn as an english one
          rrn_as_uprn_dup_sap_xml = Nokogiri.XML(Samples.xml("SAP-Schema-18.0.0"))
          rrn_as_uprn_dup_sap_xml.at("Property Address Address-Line-1").content = "1a Some Streeet"
          rrn_as_uprn_dup_sap_xml.at("RRN").content = "0000-0000-0000-0222-0111"
          lodge_assessment(
            assessment_body: rrn_as_uprn_dup_sap_xml.to_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [get_scheme_id],
            },
            schema_name: "SAP-Schema-18.0.0",
            migrated: true,
          )
          ActiveRecord::Base.connection.exec_query("UPDATE scotland.assessments_address_id SET address_id = 'RRN-0000-0000-0000-0000-0111' WHERE assessment_id = '0000-0000-0000-0000-0123' ", "SQL")
          ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id SET address_id = 'RRN-0000-0000-0000-0000-0111' WHERE assessment_id = '0000-0000-0000-0222-0111' ", "SQL")
        end

        after do
          Helper::Toggles.set_feature("register-api-allow-scottish-address-search", false)
        end

        it_behaves_like "when searching by address_id"

        it "does return the address for a Scottish UPRN" do
          address = gateway.search_by_address_id("UPRN-1234123417777777")
          expect(address.first.line1).to eq "2 McDonald Road"
        end

        it "does return a Scottish address that is an RRN" do
          address = gateway.search_by_address_id("RRN-0000-0000-0000-0000-0000")
          expect(address.first.line1).to eq "1 Scotland Road"
        end

        context "when searching an address_id that is found in both db schemas" do
          let(:addresses) { gateway.search_by_address_id("RRN-0000-0000-0000-0000-0111").sort_by(&:line1) }

          it "returns the Scottish assessments" do
            expect(addresses.first.line1).to eq "1 Scotland Street"
            expect(addresses.first.existing_assessments.length).to eq 2
            expect(addresses.first.postcode).to eq "FK1 1XE"
          end

          it "returns English assessments" do
            expect(addresses.second.line1).to eq "1 Some Street"
            expect(addresses.second.existing_assessments.length).to eq 2
            expect(addresses.second.postcode).to eq "SW1A 2AA"
          end
        end
      end
    end

    describe "#search_by_street_and_town" do
      context "when the toggle is off" do
        it_behaves_like "when searching by street and town"

        it "does not return the Scottish addresses in address base" do
          address = gateway.search_by_street_and_town("BORDER ROAD", "BORDER", nil)
          expect(address.length).to eq 1
          expect(address.first.line1).to eq "English House"
        end

        it "does not return addresses from scotland" do
          address = gateway.search_by_street_and_town("SCOTLAND ROAD", "NEWKIRK", nil)
          expect(address).to eq []
        end
      end

      context "when the toggle is on" do
        before do
          Helper::Toggles.set_feature("register-api-allow-scottish-address-search", true)
          cepc_xml = Nokogiri.XML Samples.xml("CEPC-S-7.1", "cepc")
          cepc_xml
            .xpath("//*[local-name() = 'RRN']")
            .each do |node|
            node.content = "0000-0000-0000-0002-0000"
          end
          lodge_scottish_assessment(
            assessment_body: cepc_xml.to_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [get_scheme_id],
            },
            schema_name: "CEPC-S-7.1",
            migrated: true,
          )
        end

        after do
          Helper::Toggles.set_feature("register-api-allow-scottish-address-search", false)
        end

        it_behaves_like "when searching by street and town"

        it "does returns both Scottish and English addresses from address base" do
          addresses = gateway.search_by_street_and_town("BORDER ROAD", "BORDER", nil)
          expect(addresses.length).to eq 2
          expect(addresses.first.line1).to eq "English House"
          expect(addresses.second.line1).to eq "Scottish House"
        end

        it "returns Scottish addresses not in address base" do
          address = gateway.search_by_street_and_town("SCOTLAND ROAD", "NEWKIRK", nil)
          expect(address.length).to eq 1
          expect(address.first.address_id).to eq "RRN-0000-0000-0000-0000-0000"
        end

        context "when selecting the assessment type" do
          it "returns the expected assessments" do
            address = gateway.search_by_street_and_town("Non-dom Property", "TOWN", "COMMERCIAL")
            expect(address.length).to eq 1
            expect(address[0].address_id).to eq "RRN-0000-0000-0000-0002-0000"
            expect(address[0].existing_assessments[0]["assessmentType"]).to eq "CEPC"
          end

          it "does not return the filtered the expected assessments" do
            address = gateway.search_by_street_and_town("Non-dom Property", "TOWN", "DOMESTIC")
            expect(address.length).to eq 0
          end
        end
      end
    end
  end
end
