describe Gateway::DomesticEpcSearchGateway do
  include RSpecRegisterApiServiceMixin
  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:address) do
  end

  let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
  let(:sap_xml) { Nokogiri.XML Samples.xml "SAP-Schema-18.0.0" }
  let(:cepc_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }

  before do
    add_super_assessor(scheme_id:)
  end

  context "when expecting to find one RdSAP assessment" do
    before do
      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )
    end

    let(:expected_result) do
      { address: { addressLine1: "1 Some Street",
                   addressLine2: "",
                   addressLine3: "",
                   addressLine4: "",
                   postcode: "A0 0AA",
                   town: "Whitbury" },
        epc_rrn: "0000-0000-0000-0000-0000" }
    end

    it "finds one record using the postcode and building number", aggregate_failures: true do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.length).to eq(1)
      expect(result.first).to be_a(Domain::DomesticEpcSearchResult)
      expect(result.first.to_hash).to eq(expected_result)
    end

    it "finds one record using the postcode and building name" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1 Some Street")
      expect(result.first.to_hash).to eq(expected_result)
    end
  end

  context "when there is more than one EPC for the same address" do
    before do
      do_lodgement = lambda {
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )
      }
      do_lodgement.call
      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-9999"
      do_lodgement.call
    end

    let(:expected_result) do
      {
        epc_rrn: "0000-0000-0000-0000-9999",
        address: {
          addressLine1: "1 Some Street", addressLine2: "", addressLine3: "", addressLine4: "", postcode: "A0 0AA", town: "Whitbury"
        },
      }
    end

    it "finds the latest EPC for that address (excluding the superseded)", aggregate_failures: true do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.first.to_hash).to match a_hash_including(expected_result)
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1 Some Street")
      expect(result.first.to_hash).to match a_hash_including(expected_result)
    end
  end

  context "when there is more than one assessment for the same address" do
    before do
      do_lodgement = lambda {
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )
      }
      do_lodgement.call
      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-9999"
      rdsap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Another Street" }
      rdsap_xml.at("UPRN").content = "UPRN-000111222333"
      do_lodgement.call

      sap_xml.at("RRN").content = "8989-0000-0000-0000-9999"
      sap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Domestic Street" }
      sap_xml.at("UPRN").content = "UPRN-000111222335"
      lodge_assessment(
        assessment_body: sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        schema_name: "SAP-Schema-18.0.0",
      )

      cepc_xml.at("//CEPC:RRN").content = "1000-0000-0000-0000-9999"
      cepc_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Commercial Street" }
      cepc_xml.at("//CEPC:UPRN").content = "UPRN-000111222334"
      lodge_assessment(
        assessment_body: cepc_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        schema_name: "CEPC-8.0.0",
      )
    end

    let(:expected_result) do
      [{
        epc_rrn: "0000-0000-0000-0000-0000",
        address: {
          addressLine1: "1 Some Street", addressLine2: "", addressLine3: "", addressLine4: "", postcode: "A0 0AA", town: "Whitbury"
        },
      },
       {
         epc_rrn: "0000-0000-0000-0000-9999",
         address: {
           addressLine1: "1 Another Street", addressLine2: "", addressLine3: "", addressLine4: "", postcode: "A0 0AA", town: "Whitbury"
         },
       },
       {
         epc_rrn: "8989-0000-0000-0000-9999",
         address: {
           addressLine1: "1 Domestic Street", addressLine2: "Some Area", addressLine3: "Some County", addressLine4: "", postcode: "A0 0AA", town: "Whitbury"
         },
       }]
    end

    it "finds the 3 domestic EPCs for that address" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.sort_by(&:rrn).map(&:to_hash)).to eq(expected_result)
    end

    it "has the assessments results in alpha order of address line 1" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.length).to eq(3)
      expect(result.map(&:to_hash).first[:address][:addressLine1]).to eq("1 Another Street")
    end

    it "does not find a CEPC for that address" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1 Commercial Street")
      expect(result).to eq []
    end
  end

  context "when performing a search by address where a target address has a lettered number street line like 2A" do
    before do
      xml = rdsap_xml.dup

      xml.at_css("Report-Header RRN").content = "3333-4444-5555-6666-7777"
      xml.at("UPRN").content = "UPRN-000000000001"
      xml.at_css("Property Address Address-Line-1").content = "Flat 12A Street Lane"

      add_super_assessor(scheme_id:)

      lodge_assessment(
        assessment_body: xml.to_s,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )
    end

    let(:expected_result) do
      {
        epc_rrn: "3333-4444-5555-6666-7777",
        address: {
          addressLine1: "Flat 12A Street Lane", addressLine2: "", addressLine3: "", addressLine4: "", postcode: "A0 0AA", town: "Whitbury"
        },
      }
    end

    context "when searching using correct original casing" do
      it "returns the expected BUS details" do
        result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "12A")

        expect(result.first).to be_a(Domain::DomesticEpcSearchResult)
        expect(result.first.to_hash).to eq expected_result
      end
    end

    context "when searching using incorrect original casing" do
      it "returns the expected BUS details regardless of casing" do
        result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "12a")
        expect(result.first.to_hash).to eq expected_result
      end
    end

    context "when searching using just the correct number" do
      it "finds and returns the expected results" do
        result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "12")

        expect(result.first).to be_a(Domain::DomesticEpcSearchResult)
        expect(result.length).to eq 1
      end
    end

    context "when searching using part of the number" do
      it "does not match an address with the full number" do
        result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "2")

        expect(result).to eq []
      end
    end

    context "when searching using a number which is a numeric superset of an address's street line number" do
      it "does not match BUS details for an address with the full number" do
        result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "212")

        expect(result).to eq []
      end
    end

    context "when searching using a number which is a numeric superset of an address's street line number in the middle of an address line" do
      it "does not match for an address with the full number" do
        result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
        expect(result).to eq []
      end
    end

    context "when searching using a building name that is part of a street line" do
      it "finds and returns the expected result" do
        result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "12A STREET")
        expect(result.first).to be_a(Domain::DomesticEpcSearchResult)
        expect(result.first.to_hash).to eq expected_result
      end
    end
  end

  context "when an address has an empty address line 1" do
    before do
      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET address_line2 = '1 Some Street', address_line1= '' ")
    end

    it "finds the EPC for that building number" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.length).to eq(1)
    end

    it "finds the EPC for the same building name" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1 Some Street")
      expect(result.length).to eq(1)
    end
  end

  context "when a certificate is not valid" do
    before do
      add_super_assessor(scheme_id:)

      rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      do_lodgement = lambda {
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )
      }

      do_lodgement.call
      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0001"
      rdsap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Yet Another Street" }
      rdsap_xml.at("UPRN").content = "UPRN-000111222334"
      do_lodgement.call

      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0002"
      rdsap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 More Another Street" }
      rdsap_xml.at("UPRN").content = "UPRN-000111222335"
      do_lodgement.call
    end

    it "only finds the 2 EPC that has not been cancelled" do
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.length).to eq(2)
    end

    it "only finds the 1 EPC that has not been cancelled", aggregate_failures: true do
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET not_for_issue_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0001' ", "SQL")
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.length).to eq(1)
      expect(result[0].rrn).to eq("0000-0000-0000-0000-0002")
    end

    it "only finds the 1 EPCs that has not been opted out", aggregate_failures: true do
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET opt_out = true WHERE assessment_id = '0000-0000-0000-0000-0001' ", "SQL")
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.length).to eq(1)
      expect(result[0].rrn).to eq("0000-0000-0000-0000-0002")
    end
  end
end
