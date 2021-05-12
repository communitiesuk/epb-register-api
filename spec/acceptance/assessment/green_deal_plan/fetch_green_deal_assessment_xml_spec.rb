# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlan:FetchGreenDealAssessmentXml", set_with_timecop: true do
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
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: xml_schema,
    )

    if type == "RdSAP"
      add_green_deal_plan(
        assessment_id: "0000-0000-0000-0000-0000",
        body: GreenDealPlanStub.new.request_body,
      )
    end
  end

  context "when getting a redacted green deal assessments XML" do
    it "will return the redacted XML" do
      add_assessment_with_green_deal

      xml =
        fetch_green_deal_assessment_xml(
          assessment_id: "0000-0000-0000-0000-0000",
        ).body

      expect(xml).to eq(Samples.xml("RdSAP-Schema-20.0.0", "redacted_epc"))
    end
  end

  context "when getting an assessment with a malformed RRN" do
    it "will return error 400, assessment id not valid" do
      error_response =
        fetch_green_deal_assessment_xml(
          assessment_id: "randomly-wrong-rrn",
          accepted_responses: [400],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("The requested assessment id is not valid")
    end
  end

  context "when getting a redacted assessment that is not an RdSAP" do
    it "will return error 403, assessment is not an RdSAP" do
      add_assessment_with_green_deal("CEPC")

      error_response =
        fetch_green_deal_assessment_xml(
          assessment_id: "0000-0000-0000-0000-0000",
          accepted_responses: [403],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("Assessment is not an RdSAP")
    end
  end

  context "when getting a redacted assessment that doesn't exist" do
    it "will return error 404, assessment not found" do
      error_response =
        fetch_green_deal_assessment_xml(
          assessment_id: "0000-0000-0000-0000-0000",
          accepted_responses: [404],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("Assessment not found")
    end
  end

  context "when getting a not for issue certificate" do
    it "will return error 410, assessment is gone" do
      add_assessment_with_green_deal

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

      error_response =
        fetch_green_deal_assessment_xml(
          assessment_id: "0000-0000-0000-0000-0000",
          accepted_responses: [410],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("Assessment not for issue")
    end
  end

  context "when getting a not for issue certificate" do
    it "will return error 410, assessment is gone" do
      add_assessment_with_green_deal

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

      error_response =
        fetch_green_deal_assessment_xml(
          assessment_id: "0000-0000-0000-0000-0000",
          accepted_responses: [410],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("Assessment not for issue")
    end
  end
end
