describe "Acceptance::Assessment::GreenDealPlan::PatchGreenDealPlan", :set_with_timecop do
  include RSpecRegisterApiServiceMixin
  let(:scheme_id) { add_scheme_and_get_id }
  let(:valid_request_body) do
    {
      greenDealPlanId: "ABC654321DEF",
      endDate: "2035-02-28",
      charges: [
        {
          startDate: "2020-03-29",
          endDate: "2035-02-28",
          dailyCharge: 0.34,
        },
      ],
    }
  end

  before do
    add_super_assessor(scheme_id:)
    load_green_deal_data
    add_assessment_with_green_deal(
      type: "RdSAP",
      assessment_id: "0000-0000-0000-0000-1112",
      registration_date: "2024-10-10",
      green_deal_plan_id: "ABC654321DEF",
    )
  end

  describe "patch a Green Deal Plan" do
    context "when unauthenticated" do
      it "returns status 401" do
        expect(patch_green_deal_plan(plan_id: "ABC654321DEF",
                                     body: valid_request_body,
                                     accepted_responses: [401],
                                     authenticate: false).status).to eq(401)
      end
    end

    context "when unauthorised" do
      it "returns status 403" do
        expect(patch_green_deal_plan(plan_id: "ABC654321DEF",
                                     body: valid_request_body,
                                     accepted_responses: [403],
                                     scopes: %w[wrong:scope]).status).to eq(403)
      end
    end

    context "when a plan does not exist" do
      let(:request_body) do
        {
          greenDealPlanId: "ABC123456DEA",
          endDate: "2030-02-28",
          charges: [
            {
              sequence: 0,
              startDate: "2020-03-29",
              endDate: "2030-03-29",
              dailyCharge: 0.34,
            },
          ],
        }
      end

      it "returns status 404" do
        expect(patch_green_deal_plan(plan_id: "ABC123456DEA",
                                     body: request_body,
                                     accepted_responses: [404]).status).to eq(404)
      end
    end

    context "when a plan exists" do
      it "returns a 204 status code" do
        expect(patch_green_deal_plan(plan_id: "ABC654321DEF",
                                     body: valid_request_body).status).to eq(204)
      end

      context "when the plan id parameter does not match the request body" do
        it "returns a 409 status code" do
          expect(patch_green_deal_plan(plan_id: "ABC123456DE1",
                                       body: valid_request_body,
                                       accepted_responses: [409]).status).to eq(409)
        end
      end
    end

    context "when the request payload is incorrect" do
      context "when the end date is missing" do
        let(:invalid_request_body) do
          {
            greenDealPlanId: "ABC654321DEF",
            charges: [
              {
                startDate: "2020-03-29",
                endDate: "2035-02-28",
                dailyCharge: 0.34,
              },
            ],
          }
        end

        it "returns a 400 status code" do
          expect(patch_green_deal_plan(plan_id: "ABC123456DEF",
                                       body: invalid_request_body,
                                       accepted_responses: [400]).status).to eq(400)
        end
      end

      context "when the green plan id is missing" do
        let(:invalid_request_body) do
          {
            endDate: "2035-02-28",
            charges: [
              {
                startDate: "2020-03-29",
                endDate: "2035-02-28",
                dailyCharge: 0.34,
              },
            ],
          }
        end

        it "returns a 400 status code" do
          expect(patch_green_deal_plan(plan_id: "ABC123456DEF",
                                       body: invalid_request_body,
                                       accepted_responses: [400]).status).to eq(400)
        end
      end

      context "when the charges is missing" do
        let(:invalid_request_body) do
          {
            greenDealPlanId: "ABC654321DEF",
            endDate: "2035-02-28",
          }
        end

        it "returns a 400 status code" do
          expect(patch_green_deal_plan(plan_id: "ABC123456DEF",
                                       body: invalid_request_body,
                                       accepted_responses: [400]).status).to eq(400)
        end
      end

      context "when the required field is missing from the charges" do
        let(:invalid_request_body) do
          {
            greenDealPlanId: "ABC654321DEF",
            endDate: "2035-02-28",
            charges: [
              {
                startDate: "2020-03-29",
                dailyCharge: 0.34,
              },
            ],
          }
        end

        it "returns a 400 status code" do
          expect(patch_green_deal_plan(plan_id: "ABC123456DEF",
                                       body: invalid_request_body,
                                       accepted_responses: [400]).status).to eq(400)
        end
      end
    end
  end
end
