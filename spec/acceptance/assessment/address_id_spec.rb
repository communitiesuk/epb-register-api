# frozen_string_literal: true

describe "Acceptance::AssessmentAddressId", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      domesticRdSap: "ACTIVE",
      nonDomesticNos3: "ACTIVE",
      nonDomesticCc4: "ACTIVE",
    )
  end

  let(:valid_cepc_rr_xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }
  let(:valid_aircon_rr_xml) { Samples.xml "CEPC-8.0.0", "ac-cert+ac-report" }

  context "when lodging a valid CEPC dual assessment" do
    let(:cepc_xml_doc) { Nokogiri.XML(valid_cepc_rr_xml) }

    it "successfully saves the UPRN when it exists" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      cepc_xml_doc.at("//CEPC:UPRN").children = "UPRN-000000000001"

      lodge_assessment(
        assessment_body: cepc_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0000", [200]).body,
          symbolize_names: true,
        )

      expect(response[:data][:addressId]).to eq("UPRN-000000000001")
    end
  end

  context "when lodging a valid AIRCON dual assessment" do
    let(:aircon_xml_doc) { Nokogiri.XML(valid_aircon_rr_xml) }

    it "assign the same address ID to both assessments when when UPRN doesn't exist" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: aircon_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      response1 =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0000", [200]).body,
          symbolize_names: true,
        )
      response2 =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001", [200]).body,
          symbolize_names: true,
        )

      expected_address_id = "UPRN-432167890000"

      expect(response1[:data][:addressId]).to eq expected_address_id
      expect(response2[:data][:addressId]).to eq expected_address_id
    end
  end
end
