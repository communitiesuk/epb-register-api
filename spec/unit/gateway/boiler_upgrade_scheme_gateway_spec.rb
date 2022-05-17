describe Gateway::BoilerUpgradeSchemeGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  context "when expecting to find one RdSAP assessment" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id: scheme_id)

      rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )
    end

    expected_bus_details_hash = {
      epc_rrn: "0000-0000-0000-0000-0000",
      report_type: "RdSAP",
      expiry_date: "2030-05-03",
      cavity_wall_insulation_recommended: false,
      loft_insulation_recommended: false,
      secondary_heating: "Room heaters, electric",
      address: {
        address_id: "UPRN-000000000000",
        address_line1: "1 Some Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwelling_type: "Mid-terrace house",
    }

    context "when searching by postcode and building identifier" do
      it "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "1")

        expect(result).to be_a(Domain::AssessmentBusDetails)
        expect(result.to_hash).to eq expected_bus_details_hash
      end

      it "returns nil when no match" do
        expect(gateway.search_by_postcode_and_building_identifier(postcode: "AB1 2CD", building_identifier: "2")).to be_nil
      end
    end

    context "when searching by UPRN" do
      it "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.search_by_uprn("UPRN-000000000000")

        expect(result).to be_a(Domain::AssessmentBusDetails)
        expect(result.to_hash).to eq expected_bus_details_hash
      end

      it "returns nil when no match" do
        expect(gateway.search_by_uprn("UPRN-012345678912")).to be_nil
      end
    end

    context "when searching by RRN" do
      it "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.search_by_rrn("0000-0000-0000-0000-0000")

        expect(result).to be_a(Domain::AssessmentBusDetails)
        expect(result.to_hash).to eq expected_bus_details_hash
      end

      it "returns nil when no match" do
        expect(gateway.search_by_rrn("0000-1111-2222-3333-4444")).to be_nil
      end
    end
  end

  context "when expecting to find two RdSAP assessments" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id: scheme_id)

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
      rdsap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Another Street" }
      rdsap_xml.at("UPRN").content = "UPRN-000111222333"

      do_lodgement.call
    end

    context "when performing a postcode and building identifier lookup" do
      it "returns the assessments as a reference list" do
        result = gateway.search_by_postcode_and_building_identifier postcode: "A0 0AA", building_identifier: "1"
        expect(result).to be_a Domain::AssessmentReferenceList
        expect(result.references).to eq %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001]
      end
    end
  end

  context "when there are multiple RdSAP certificates for the same address" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id: scheme_id)

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
      rdsap_xml.at("Completion-Date").content = "2025-05-04"
      rdsap_xml.at("Registration-Date").content = "2025-05-04"

      do_lodgement.call
    end

    context "when performing a postcode and building identifier lookup" do
      it "returns the latest assessment as a details object" do
        result = gateway.search_by_postcode_and_building_identifier postcode: "A0 0AA", building_identifier: "1"
        expect(result).to be_a Domain::AssessmentBusDetails
        expect(result.to_hash[:epc_rrn]).to eq "0000-0000-0000-0000-0001"
      end

      context "with a postcode not canonically formed" do
        it "returns the latest assessment as a details object" do
          result = gateway.search_by_postcode_and_building_identifier postcode: "a00aa", building_identifier: "1"
          expect(result).to be_a Domain::AssessmentBusDetails
          expect(result.to_hash[:epc_rrn]).to eq "0000-0000-0000-0000-0001"
        end
      end

      context "with a building name or number containing an unexpected character like a colon" do
        it "returns the latest assessment as a details object" do
          result = gateway.search_by_postcode_and_building_identifier postcode: "A0 0AA", building_identifier: "1:"
          expect(result).to be_a Domain::AssessmentBusDetails
          expect(result.to_hash[:epc_rrn]).to eq "0000-0000-0000-0000-0001"
        end
      end
    end
  end

  context "when expecting to find one SAP assessment" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id: scheme_id)

      sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
      lodge_assessment(
        assessment_body: sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-18.0.0",
        override: true,
      )
    end

    expected_bus_details_hash = {
      epc_rrn: "0000-0000-0000-0000-0000",
      report_type: "SAP",
      expiry_date: "2030-05-03",
      cavity_wall_insulation_recommended: false,
      loft_insulation_recommended: false,
      secondary_heating: "Electric heater",
      address: {
        address_id: "UPRN-000000000000",
        address_line1: "1 Some Street",
        address_line2: "Some Area",
        address_line3: "Some County",
        address_line4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwelling_type: "Mid-terrace house",
    }

    context "when searching by postcode and building identifier" do
      it "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "1")

        expect(result).to be_a(Domain::AssessmentBusDetails)
        expect(result.to_hash).to eq expected_bus_details_hash
      end
    end

    context "when searching by UPRN" do
      it "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.search_by_uprn("UPRN-000000000000")

        expect(result).to be_a(Domain::AssessmentBusDetails)
        expect(result.to_hash).to eq expected_bus_details_hash
      end
    end
  end

  context "when expecting to find one CEPC" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id: scheme_id)

      cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      lodge_assessment(
        assessment_body: cepc_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        override: true,
      )
    end

    expected_bus_details_hash = {
      epc_rrn: "0000-0000-0000-0000-0000",
      report_type: "CEPC",
      expiry_date: "2026-05-04",
      cavity_wall_insulation_recommended: nil,
      loft_insulation_recommended: nil,
      secondary_heating: nil,
      address: {
        address_id: "UPRN-000000000001",
        address_line1: "Some Unit",
        address_line2: "2 Lonely Street",
        address_line3: "Some Area",
        address_line4: "Some County",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwelling_type: "B1 Offices and Workshop businesses",
    }

    context "when searching by postcode and building identifier" do
      it "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.search_by_postcode_and_building_identifier(postcode: "A0 0AA", building_identifier: "2")

        expect(result).to be_a(Domain::AssessmentBusDetails)
        expect(result.to_hash).to eq expected_bus_details_hash
      end
    end

    context "when searching by UPRN" do
      it "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.search_by_uprn("UPRN-000000000001")

        expect(result).to be_a(Domain::AssessmentBusDetails)
        expect(result.to_hash).to eq expected_bus_details_hash
      end
    end
  end
end
