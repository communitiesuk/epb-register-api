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

  context "when getting an assessment without the correct permissions" do
    it "will return error 403" do
      add_assessment_with_green_deal("RdSAP")

      error_response =
        fetch_green_deal_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
          accepted_responses: [403],
          scopes: %w[not_allowed_to_access:plans],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("You are not authorised to perform this request")
    end
  end

  context "when getting an assessment that does not exist" do
    it "will return error 404" do
      error_response =
        fetch_green_deal_assessment(
          assessment_id: "0000-0000-0000-0000-0000", accepted_responses: [404],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("Assessment not found")
    end
  end

  context "when assessment ID is not valid" do
    it "will return error 400" do
      error_response =
        fetch_green_deal_assessment(
          assessment_id: "abcd", accepted_responses: [400],
        ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("The requested assessment ID is not valid")
    end
  end

  context "when assessment status is cancelled or not for issue" do
    it "will return error 410" do
      add_assessment_with_green_deal("RdSAP")

      update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                               assessment_status_body: { "status": "CANCELLED" },
                               accepted_responses: [200],
                               auth_data: { scheme_ids: [scheme_id] }

      error_response = fetch_green_deal_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        accepted_responses: [410],
      ).body

      expect(
        JSON.parse(error_response, symbolize_names: true)[:errors].first[:title],
      ).to eq("Assessment not for issue")
    end
  end

  context "when getting a valid RDSAP assessment" do
    it "will return the assessments details" do
      add_assessment_with_green_deal("RdSAP")

      response =
        fetch_green_deal_assessment(assessment_id: "0000-0000-0000-0000-0000")
          .body

      expect(
        JSON.parse(response, symbolize_names: true)[:data][:assessment],
      ).to eq(
        {
          typeOfAssessment: "RdSAP",
          address: {
            line1: "1 Some Street",
            line2: "",
            line3: "",
            line4: "",
            postcode: "A0 0AA",
            town: "Post-Town1",
          },
          addressId: "UPRN-000000000000",
          countryCode: "EAW",
          inspectionDate: "2020-05-04",
          lodgementDate: "2020-05-04",
          status: "ENTERED",
          mainFuelType: "26",
          secondaryFuelType: "25",
          waterHeatingFuel: "26",
        },
      )
    end
  end
end
