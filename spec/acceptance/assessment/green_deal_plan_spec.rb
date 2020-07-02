# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlans" do
  include RSpecAssessorServiceMixin

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
  end

  describe "creating a green deal plan" do
    context "when unauthenticated" do
      it "returns status 401" do
        add_green_deal_plan "123-456", "body", [401], false
      end
    end

    context "when unauthorised" do
      it "returns status 401" do
        add_green_deal_plan "123-456", "body", [403], true, nil, %w[wrong:scope]
      end
    end

    context "when an assessment does not exist" do
      it "returns status 404" do
        add_green_deal_plan "123-456", "body", [404]
      end
    end

    context "when an assessment does exist" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor scheme_id,
                     "SPEC000000",
                     AssessorStub.new.fetch_request_body(
                       domesticRdSap: "ACTIVE",
                     )

        lodge_assessment assessment_body: valid_rdsap_xml,
                         accepted_responses: [201],
                         auth_data: { scheme_ids: [scheme_id] }
      end

      context "with a cancelled assessment" do
        before do
          update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                                   assessment_status_body: {
                                     "status": "CANCELLED",
                                   },
                                   accepted_responses: [200],
                                   auth_data: { scheme_ids: [scheme_id] }
        end

        it "returns status 410" do
          add_green_deal_plan "0000-0000-0000-0000-0000", "body", [410]
        end
      end

      context "with a not for issue assessment" do
        before do
          update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                                   assessment_status_body: {
                                     "status": "NOT_FOR_ISSUE",
                                   },
                                   accepted_responses: [200],
                                   auth_data: { scheme_ids: [scheme_id] }
        end

        it "returns status 410" do
          add_green_deal_plan "0000-0000-0000-0000-0000", "body", [410]
        end
      end
    end
  end
end
