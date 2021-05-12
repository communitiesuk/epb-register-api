# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlan:DeleteGreenDealPlan", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  describe "deleting a green deal plan" do
    context "when unauthenticated" do
      it "returns status 401" do
        delete_green_deal_plan plan_id: "AD0000002312",
                               accepted_responses: [401],
                               authenticate: false
      end
    end

    context "when unauthorised" do
      it "returns status 403" do
        delete_green_deal_plan plan_id: "AD0000002312",
                               accepted_responses: [403],
                               scopes: %w[wrong:scope]
      end
    end

    context "when a plan_id does not exists" do
      it "returns status 404" do
        delete_green_deal_plan plan_id: "AD0000002311",
                               accepted_responses: [404]
      end
    end

    context "when a green deal plan exists" do
      let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

      let(:valid_green_deal_plan_request_body) do
        {
          greenDealPlanId: "ABC123456DEF",
          startDate: "2020-01-30",
          endDate: "2030-02-28",
          providerDetails: {
            name: "The Bank",
            telephone: "0800 0000000",
            email: "lender@example.com",
          },
          interest: {
            rate: 12.3,
            fixed: true,
          },
          chargeUplift: {
            amount: 1.25,
            date: "2025-03-29",
          },
          ccaRegulated: true,
          structureChanged: false,
          measuresRemoved: false,
          measures: [
            {
              sequence: 0,
              measureType: "Loft insulation",
              product: "WarmHome lagging stuff (TM)",
              repaidDate: "2025-03-29",
            },
          ],
          charges: [
            {
              sequence: 0,
              startDate: "2020-03-29",
              endDate: "2030-03-29",
              dailyCharge: 0.34,
            },
          ],
          savings: [
            {
              sequence: 0,
              fuelCode: "3",
              fuelSaving: 9000.1,
              standingChargeFraction: -0.3,
            },
          ],
        }
      end

      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor scheme_id,
                     "SPEC000000",
                     AssessorStub.new.fetch_request_body(
                       domesticRdSap: "ACTIVE",
                     )

        lodge_assessment assessment_body: valid_rdsap_xml,
                         auth_data: {
                           scheme_ids: [scheme_id],
                         }

        add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                            body: valid_green_deal_plan_request_body
      end

      def response
        JSON.parse(fetch_assessment_summary("0000-0000-0000-0000-0000").body)
      end

      it "returns status code 204" do
        delete_green_deal_plan plan_id: "ABC123456DEF",
                               accepted_responses: [204]
      end

      it "deletes the green deal plan" do
        expect(response["data"]["greenDealPlan"]).not_to be_nil

        delete_green_deal_plan plan_id: "ABC123456DEF",
                               accepted_responses: [204]

        expect(response["data"]["greenDealPlan"]).to eq([])
      end
    end
  end
end
