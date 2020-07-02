# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlans" do
  include RSpecAssessorServiceMixin

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
  end

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end

  describe "creating a green deal plan" do
    context "when unauthenticated" do
      it "returns status 401" do
        add_green_deal_plan assessment_id: "1234-1234-1234-1234-1234",
                            accepted_responses: [401],
                            authenticate: false
      end
    end

    context "when unauthorised" do
      it "returns status 401" do
        add_green_deal_plan assessment_id: "1234-1234-1234-1234-1234",
                            accepted_responses: [403],
                            scopes: %w[wrong:scope]
      end
    end

    context "when an assessment does not exist" do
      it "returns status 404" do
        add_green_deal_plan assessment_id: "1234-1234-1234-1234-1234",
                            accepted_responses: [404]
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
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                              accepted_responses: [410]
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
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                              accepted_responses: [410]
        end
      end

      context "with wrong assessment type" do
        let(:sap_assessment) { Nokogiri.XML valid_sap_xml }
        let(:assessment_id) { sap_assessment.at "RRN" }

        before do
          add_assessor scheme_id,
                       "SPEC000000",
                       AssessorStub.new.fetch_request_body(
                         domesticSap: "ACTIVE",
                       )

          assessment_id.children = "0000-0000-0000-0000-0001"

          lodge_assessment assessment_body: sap_assessment.to_xml,
                           accepted_responses: [201],
                           auth_data: { scheme_ids: [scheme_id] },
                           schema_name: "SAP-Schema-17.1"
        end

        it "returns status 400" do
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0001",
                              accepted_responses: [400]
        end
      end
    end
  end
end
