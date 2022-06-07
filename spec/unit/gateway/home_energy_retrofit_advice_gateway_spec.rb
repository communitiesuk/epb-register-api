describe Gateway::HomeEnergyRetrofitAdviceGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

  context "when expecting to find an RdSAP assessment" do
    before do
      add_super_assessor(scheme_id:)

      rdsap_ni_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-NI-20.0.0")
      rdsap_ni_xml.at("RRN").content = "0000-0000-0000-0000-0001"

      cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      cepc_xml.at("//CEPC:RRN").content = "0000-0000-0000-0000-0002"

      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )

      lodge_assessment(
        assessment_body: rdsap_ni_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-NI-20.0.0",
        override: true,
      )

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

    context "when fetching by RRN" do
      it "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.fetch_by_rrn("0000-0000-0000-0000-0000")

        expect(result["schema_type"]).to eq "RdSAP-Schema-20.0.0"
        expect(Hash.from_xml(result["xml"])).to eq Hash.from_xml(rdsap_xml.to_s)
      end

      it "does not find and return the expected data when the rrn is for a NI cert", aggregate_failures: true do
        expect(gateway.fetch_by_rrn("0000-0000-0000-0000-0001")).to be_nil
      end

      it "does not find and return the expected data when the rrn is for a CEPC cert", aggregate_failures: true do
        expect(gateway.fetch_by_rrn("0000-0000-0000-0000-0002")).to be_nil
      end

      it "returns nil when no match" do
        expect(gateway.fetch_by_rrn("0000-1111-2222-3333-4444")).to be_nil
      end

      context "with a RRN that has been previously cancelled" do
        before do
          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: {
              "status": "CANCELLED",
            },
            accepted_responses: [200],
            auth_data: {
              scheme_ids: [scheme_id],
            },
          )
        end

        it "returns nil" do
          expect(gateway.fetch_by_rrn("0000-0000-0000-0000-0000")).to be_nil
        end
      end

      context "with a RRN that has been previously marked as not for issue" do
        before do
          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: {
              "status": "NOT_FOR_ISSUE",
            },
            accepted_responses: [200],
            auth_data: {
              scheme_ids: [scheme_id],
            },
          )
        end

        it "returns nil" do
          expect(gateway.fetch_by_rrn("0000-0000-0000-0000-0000")).to be_nil
        end
      end
    end
  end
end
