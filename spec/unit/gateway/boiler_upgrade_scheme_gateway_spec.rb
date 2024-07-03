describe Gateway::BoilerUpgradeSchemeGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

  context "when expecting to find one RdSAP assessment" do
    before do
      add_super_assessor(scheme_id:)

      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
    end

    context "when searching by postcode and building identifier" do
      it "finds and returns the expected data when one match exists", :aggregate_failures do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "1")
        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
      end

      context "with a postcode not canonically formed" do
        it "returns the relevant assessments" do
          result = gateway.search_by_postcode_and_building_identifier postcode: "a00aa", building_identifier: "1"
          expect(result.count).to eq 1
          expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
        end
      end

      context "with a building name or number containing an unexpected character like a colon" do
        it "returns the relevant assessments" do
          result = gateway.search_by_postcode_and_building_identifier postcode: "A0 0AA", building_identifier: "1:"
          expect(result.count).to eq 1
          expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
        end
      end

      it "returns nil when no match" do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "AB1 2CD", building_identifier: "2")
        expect(result).to be_nil
      end
    end

    context "when searching by UPRN" do
      it "finds and returns the expected data when one match exists", :aggregate_failures do
        result = gateway.search_by_uprn("UPRN-000000000000")
        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
      end

      it "returns nil when no match" do
        expect(gateway.search_by_uprn("UPRN-012345678912")).to be_nil
      end
    end

    context "when searching by RRN" do
      it "finds and returns the expected data when one match exists", :aggregate_failures do
        result = gateway.search_by_rrn("0000-0000-0000-0000-0000")
        expect(result["report_type"]).to eq "RdSAP"
      end

      it "returns nil when no match" do
        expect(gateway.search_by_rrn("0000-1111-2222-3333-4444")).to be_nil
      end
    end
  end

  context "when there are multiple assessments for the same address but different uprns" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id:)

      rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      do_lodgement = lambda {
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      }

      do_lodgement.call

      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0001"
      rdsap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Another Street" }
      rdsap_xml.at("UPRN").content = "RRN-0000-0000-0000-0000-0001"

      do_lodgement.call
    end

    context "when performing a postcode and building identifier lookup" do
      it "returns the details for all the assessments at that address" do
        result = gateway.search_by_postcode_and_building_identifier postcode: "A0 0AA", building_identifier: "1"
        expect(result.count).to eq 2
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0001"
        expect(result[1]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
      end
    end

    context "when performing a uprn lookup" do
      it "only returns the details for the correct uprn" do
        result = gateway.search_by_uprn("RRN-0000-0000-0000-0000-0001")
        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0001"
      end
    end
  end

  context "when there are multiple RdSAP certificates for the same address with the same uprn" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id:)

      rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      do_lodgement = lambda {
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      }

      do_lodgement.call

      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0001"
      rdsap_xml.at("Completion-Date").content = "2025-05-04"
      rdsap_xml.at("Registration-Date").content = "2025-05-04"

      do_lodgement.call
    end

    context "when performing a uprn lookup" do
      it "returns the most recent, non superseded result for that uprn" do
        result = gateway.search_by_uprn("UPRN-000000000000")
        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0001"
      end
    end

    context "when performing a postcode and building identifier lookup" do
      it "returns the most recent, non superseded result" do
        result = gateway.search_by_postcode_and_building_identifier postcode: "A0 0AA", building_identifier: "1"
        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0001"
      end
    end
  end

  context "when expecting to find one SAP assessment" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id:)

      sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
      lodge_assessment(
        assessment_body: sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-18.0.0",
        migrated: true,
      )
    end

    context "when searching by postcode and building identifier" do
      it "finds and returns the expected data when one match exists", :aggregate_failures do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "1")

        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
      end
    end

    context "when searching by UPRN" do
      it "finds and returns the expected data when one match exists", :aggregate_failures do
        result = gateway.search_by_uprn("UPRN-000000000000")

        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
      end
    end
  end

  context "when expecting to find one CEPC" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id:)

      cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      lodge_assessment(
        assessment_body: cepc_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        migrated: true,
      )
    end

    context "when searching by postcode and building identifier" do
      it "finds and returns the expected data when one match exists", :aggregate_failures do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "2")

        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
      end
    end

    context "when searching by UPRN" do
      it "finds and returns the expected data when one match exists", :aggregate_failures do
        result = gateway.search_by_uprn("UPRN-000000000001")

        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0000"
      end
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
        migrated: true,
      )
    end

    context "when searching using correct original casing" do
      it "returns the expected BUS details" do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "12A")

        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "3333-4444-5555-6666-7777"
      end
    end

    context "when searching using incorrect original casing" do
      it "returns the expected BUS details regardless of casing" do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "12a")

        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "3333-4444-5555-6666-7777"
      end
    end

    context "when searching using just the correct number" do
      it "finds and returns the expected BUS details" do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "12")

        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "3333-4444-5555-6666-7777"
      end
    end

    context "when searching using part of the number" do
      it "does not match BUS details for an address with the full number" do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "2")

        expect(result).to be_nil
      end
    end

    context "when searching using a number which is a numeric superset of an address's street line number" do
      it "does not match BUS details for an address with the full number" do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "212")

        expect(result).to be_nil
      end
    end

    context "when searching using a number which is a numeric superset of an address's street line number in the middle of an address line" do
      it "does not match BUS details for an address with the full number" do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "1")

        expect(result).to be_nil
      end
    end

    context "when searching using a building name that is part of a street line" do
      it "finds and returns the expected BUS details" do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "12A STREET")

        expect(result.count).to eq 1
        expect(result[0]["epc_rrn"]).to eq "3333-4444-5555-6666-7777"
      end
    end
  end

  context "when a certificate is cancelled, marked not for issue, or opted out" do
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
          migrated: true,
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

      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0003"
      rdsap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 More Another Street" }
      rdsap_xml.at("UPRN").content = "UPRN-000111222336"
      do_lodgement.call

      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0004"
      rdsap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 More Another Street" }
      rdsap_xml.at("UPRN").content = "UPRN-000111222337"
      do_lodgement.call

      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET not_for_issue_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0001' ", "SQL")
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0002")
    end

    it "only finds the 2 EPC that have not been cancelled when searching by postcode and building identifier" do
      result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "1")
      expect(result.count).to eq(2)
      expect(result[0]["epc_rrn"]).to eq "0000-0000-0000-0000-0003"
      expect(result[1]["epc_rrn"]).to eq "0000-0000-0000-0000-0004"
    end
  end
end
