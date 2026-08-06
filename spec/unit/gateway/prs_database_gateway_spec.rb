describe Gateway::PrsDatabaseGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:expected_response_rrn) do
    {
      "address_line1" => "1 Some Street",
      "address_line2" => "",
      "address_line3" => "",
      "address_line4" => "",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0000-0000-0000-0000-0000",
      "expiry_date" => "2030-05-03",
      "latest_epc_rrn_for_address" => "0000-0000-0000-0000-0002",
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "type_of_assessment" => "RdSAP",
    }
  end

  let(:expected_response_non_dom_rrn) do
    {
      "address_line1" => "Some Unit",
      "address_line2" => "2 Lonely Street",
      "address_line3" => "Some Area",
      "address_line4" => "Some Area",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 80,
      "epc_rrn" => "0000-0000-0000-0000-0001",
      "expiry_date" => "2026-05-04",
      "latest_epc_rrn_for_address" => nil,
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "type_of_assessment" => "CEPC",
    }
  end

  let(:expected_rdsap_response_uprn) do
    {
      "address_line1" => "1 Some Street",
      "address_line2" => "",
      "address_line3" => "",
      "address_line4" => "",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0000-0000-0000-0000-0002",
      "expiry_date" => "2035-05-03",
      "latest_epc_rrn_for_address" => "0000-0000-0000-0000-0002",
      "type_of_assessment" => "RdSAP",
    }
  end

  let(:expected_sap_response_uprn) do
    {
      "address_line1" => "1 Some Street",
      "address_line2" => "Some Area",
      "address_line3" => "Some County",
      "address_line4" => "Some County",
      "current_energy_efficiency_rating" => 72,
      "epc_rrn" => "0000-0000-0000-0000-0003",
      "expiry_date" => "2032-05-08",
      "latest_epc_rrn_for_address" => "0000-0000-0000-0000-0003",
      "postcode" => "SW1A 2AA",
      "town" => "Whitbury",
      "type_of_assessment" => "SAP",
    }
  end

  before do
    add_super_assessor(scheme_id:)

    cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
    cepc_xml.at("//CEPC:RRN").children = "0000-0000-0000-0000-0001"
    lodge_assessment(
      assessment_body: cepc_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "CEPC-8.0.0",
      migrated: true,
    )

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

    rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0002"
    rdsap_xml.at("Completion-Date").content = "2025-05-04"
    rdsap_xml.at("Registration-Date").content = "2025-05-04"

    do_lodgement.call

    add_uprns_to_address_base 3
    sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
    do_lodgement = lambda {
      lodge_assessment(
        assessment_body: sap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        schema_name: "SAP-Schema-19.0.0",
      )
    }

    sap_xml.at("RRN").content = "0000-0000-0000-0000-0003"
    sap_xml.at("UPRN").content = "UPRN-000000000003"

    do_lodgement.call
  end

  context "when searching by UPRN" do
    it "finds and returns an RdSAP when one match exists", :aggregate_failures do
      result = gateway.search_by_uprn("UPRN-000000000000")
      expect(result).to eq expected_rdsap_response_uprn
    end

    it "finds and returns a SAP when one match exists", :aggregate_failures do
      result = gateway.search_by_uprn("UPRN-000000000003")
      expect(result).to eq expected_sap_response_uprn
    end

    it "returns nil when no match" do
      expect(gateway.search_by_uprn("UPRN-012345678912")).to be_nil
    end

    context "with a cancelled certificate" do
      before do
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0002",
          assessment_status_body: {
            status: "CANCELLED",
          },
          auth_data: {
            scheme_ids: [scheme_id],
          },
          accepted_responses: [200],
        )
      end

      it "does not return the cancelled certificate" do
        result = gateway.search_by_uprn("UPRN-000000000000")
        expect(result).to include("epc_rrn" => "0000-0000-0000-0000-0000")
      end
    end

    context "with a not for issue certificate" do
      before do
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0002",
          assessment_status_body: {
            status: "NOT_FOR_ISSUE",
          },
          auth_data: {
            scheme_ids: [scheme_id],
          },
          accepted_responses: [200],
        )
      end

      it "does not return the not for issue certificate" do
        result = gateway.search_by_uprn("UPRN-000000000000")
        expect(result).to include("epc_rrn" => "0000-0000-0000-0000-0000")
      end
    end

    context "with an opted-out certificate" do
      before do
        opt_out_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
        )
      end

      it "does return the opted-out certificate" do
        result = gateway.search_by_uprn("UPRN-000000000000")
        expect(result).to include("epc_rrn" => "0000-0000-0000-0000-0002")
      end
    end

    context "when the UPRN was different at lodgement for the same property" do
      before do
        rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")

        rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0003"
        rdsap_xml.at("UPRN").content = "UPRN-100099997678"
        rdsap_xml.at("Completion-Date").content = "2018-05-05"
        rdsap_xml.at("Registration-Date").content = "2018-05-05"

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

        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0003",
          new_address_id: "UPRN-000000000000",
        )
      end

      it "returns the most recent assessment" do
        result = gateway.search_by_uprn("UPRN-000000000000")
        expect(result).to eq expected_rdsap_response_uprn
      end
    end

    context "with a more recent non-domestic lodgement at the same address" do
      before do
        cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
        cepc_xml.at("//CEPC:RRN").children = "0000-0000-0000-0000-0003"
        cepc_xml.at("//CEPC:UPRN").children = "UPRN-000000000000"
        cepc_xml.at("//CEPC:Valid-Until").children = "2035-05-04"
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

      it "returns the most recent domestic assessment" do
        result = gateway.search_by_uprn("UPRN-000000000000")
        expect(result).to include("type_of_assessment" => "RdSAP")
      end
    end
  end

  context "when searching by RRN" do
    it "finds and returns the expected data when one match exists", :aggregate_failures do
      result = gateway.search_by_rrn("0000-0000-0000-0000-0000")
      expect(result).to eq expected_response_rrn
    end

    it "returns nil when no match" do
      expect(gateway.search_by_rrn("0000-1111-2222-3333-4444")).to be_nil
    end

    it "finds and returns the expected data when one match exists for a non-dom certificate" do
      result = gateway.search_by_rrn("0000-0000-0000-0000-0001")
      expect(result).to eq expected_response_non_dom_rrn
    end

    context "with an opted-out certificate" do
      before do
        opt_out_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
        )
      end

      it "returns the opted-out certificate" do
        result = gateway.search_by_rrn("0000-0000-0000-0000-0000")
        expect(result).to include("epc_rrn" => "0000-0000-0000-0000-0000")
      end
    end

    context "with a cancelled certificate" do
      before do
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: {
            status: "CANCELLED",
          },
          auth_data: {
            scheme_ids: [scheme_id],
          },
          accepted_responses: [200],
        )
      end

      it "does not return the cancelled certificate" do
        result = gateway.search_by_rrn("0000-0000-0000-0000-0000")
        expect(result).to be_nil
      end
    end

    context "with a not for issue certificate" do
      before do
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: {
            status: "NOT_FOR_ISSUE",
          },
          auth_data: {
            scheme_ids: [scheme_id],
          },
          accepted_responses: [200],
        )
      end

      it "does not return the cancelled certificate" do
        result = gateway.search_by_rrn("0000-0000-0000-0000-0000")
        expect(result).to be_nil
      end
    end

    context "with a more recent non-domestic lodgement at the same address" do
      before do
        cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
        cepc_xml.at("//CEPC:RRN").children = "0000-0000-0000-0000-0003"
        cepc_xml.at("//CEPC:Valid-Until").children = "2035-05-04"
        lodge_assessment(
          assessment_body: cepc_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
          migrated: true,
        )
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
        )
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0003",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
        )
      end

      it "does not include the non-domestic lodgement in the latest_epc_rnn_for_address" do
        result = gateway.search_by_rrn("0000-0000-0000-0000-0000")
        expect(result).to include("latest_epc_rrn_for_address" => "0000-0000-0000-0000-0000")
      end
    end

    context "with a more recent cancelled lodgement at the same address" do
      before do
        rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")

        rdsap_xml.at("RRN").children = "0000-0000-0000-0000-0003"
        rdsap_xml.at("Completion-Date").content = "2026-05-04"
        rdsap_xml.at("Registration-Date").content = "2026-05-04"

        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
        )
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0003",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
        )
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0003",
          assessment_status_body: {
            status: "CANCELLED",
          },
          auth_data: {
            scheme_ids: [scheme_id],
          },
          accepted_responses: [200],
        )
      end

      it "does not include the cancelled lodgement in the latest_epc_rnn_for_address" do
        result = gateway.search_by_rrn("0000-0000-0000-0000-0000")
        expect(result).to include("latest_epc_rrn_for_address" => "0000-0000-0000-0000-0000")
      end
    end
  end
end
