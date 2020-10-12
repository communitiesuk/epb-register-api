# frozen_string_literal: true

describe "Acceptance::Reports::GetAssessmentCountByRegionAndType" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      domesticRdSap: "ACTIVE", nonDomesticNos3: "ACTIVE",
    )
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  context "when getting a report on the number of lodged assessments" do
    let(:cepc_xml_doc) { Nokogiri.XML(valid_cepc_rr_xml) }

    it "returns a CSV with headers and data included" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      response =
        get_assessment_report(start_date: "2020-05-04", end_date: "2020-05-05")
          .body

      expect(response).to eq(
        "number_of_assessments,type_of_assessment,region\n1,RdSAP,\n",
      )
    end
  end
end
