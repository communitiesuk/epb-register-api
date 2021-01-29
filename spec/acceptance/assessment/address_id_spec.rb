# frozen_string_literal: true

describe "Acceptance::AssessmentAddressId" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      domesticRdSap: "ACTIVE",
      nonDomesticNos3: "ACTIVE",
    )
  end

  let(:valid_cepc_rr_xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }

  context "when lodging a valid assessment" do
    let(:cepc_xml_doc) { Nokogiri.XML(valid_cepc_rr_xml) }

    it "falls back to the RRN for the address_id when UPRN doesn't exist" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: cepc_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      address_id =
        ActiveRecord::Base
          .connection
          .execute("SELECT * FROM assessments_address_id")
          .first

      expect(address_id["address_id"]).to eq("RRN-0000-0000-0000-0000-0000")
    end

    it "successfully saves the UPRN when it exists" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      cepc_xml_doc.at("//CEPC:UPRN").children = "UPRN-000000000001"

      add_address_base(uprn: "1")

      lodge_assessment(
        assessment_body: cepc_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      address_id =
        ActiveRecord::Base
          .connection
          .execute("SELECT * FROM assessments_address_id")
          .first

      expect(address_id["address_id"]).to eq("UPRN-000000000001")
    end
  end
end
