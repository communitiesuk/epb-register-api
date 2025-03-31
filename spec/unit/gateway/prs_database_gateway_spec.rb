describe Gateway::PrsDatabaseGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:expected_response_rrn) {
    {
      "address_line1" => "1 Some Street",
      "address_line2" => "",
      "address_line3" => "",
      "address_line4" => "",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0000-0000-0000-0000-0000",
      "expiry_date" => "2030-05-03 00:00:00.000000000 +0000"
    }
  }

  let(:expected_response_uprn) {
    {
      "address_line1" => "1 Some Street",
      "address_line2" => "",
      "address_line3" => "",
      "address_line4" => "",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0000-0000-0000-0000-0002",
      "expiry_date" => "2035-05-03 00:00:00.000000000 +0000",
      "rn" => 1
    }
  }

  context "when expecting to find one RdSAP assessment" do
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
    end


    context "when searching by UPRN" do
      it "finds and returns the expected data when one match exists", :aggregate_failures do
        result = gateway.search_by_uprn("UPRN-000000000000")
        expect(result.count).to eq 1
        expect(result[0]).to eq expected_response_uprn
      end

      it "returns nil when no match" do
        expect(gateway.search_by_uprn("UPRN-012345678912")).to be_nil
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

      it "returns nil when the rrn is for a non-dom certificate" do
        expect(gateway.search_by_rrn("0000-0000-0000-0000-0001")).to be_nil
      end
    end
  end
end
