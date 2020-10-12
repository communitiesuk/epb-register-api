# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlan:FetchGreenDealAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }

  def add_assessment_with_green_deal(type = "RdSAP")
    case type
    when "RdSAP"
      assessor_qualifications = { domesticRdSap: "ACTIVE" }
      xml = Samples.xml("RdSAP-Schema-20.0.0")
      xml_schema = "RdSAP-Schema-20.0.0"
    when "CEPC"
      assessor_qualifications = { nonDomesticNos3: "ACTIVE" }
      xml = Samples.xml("CEPC-8.0.0", "cepc")
      xml_schema = "CEPC-8.0.0"
    end

    assessor = AssessorStub.new.fetch_request_body(assessor_qualifications)
    add_assessor(scheme_id, "SPEC000000", assessor)

    lodge_assessment(
      assessment_body: xml,
      auth_data: { scheme_ids: [scheme_id] },
      schema_name: xml_schema,
    )

    if type == "RdSAP"
      add_green_deal_plan(
        assessment_id: "0000-0000-0000-0000-0000",
        body: GreenDealPlanStub.new.request_body,
      )
    end
  end

  context "when getting an assessment with a malformed RRN" do
    it "will return error 400, assessment id not valid" do
      error_response =
        fetch_green_deal_assessment(
          assessment_id: "randomly-wrong-rrn", accepted_responses: [400],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("The assessmentId parameter is badly formatted")
    end
  end
end
