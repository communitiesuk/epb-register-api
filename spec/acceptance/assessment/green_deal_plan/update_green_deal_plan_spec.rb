# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlan:UpdateGreenDealPlan" do
  include RSpecAssessorServiceMixin

  let(:valid_green_deal_plan_request_body) do
    {
      greenDealPlanId: "ABC123456DEF",
      startDate: "2020-01-30",
      endDate: "2030-02-28",
      providerDetails: {
        name: "The Bank", telephone: "0800 0000000", email: "lender@example.com"
      },
      interest: { rate: 12.3, fixed: true },
      chargeUplift: { amount: 1.25, date: "2025-03-29" },
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
          fuelCode: "LPG",
          fuelSaving: 9000.1,
          standingChargeFraction: -0.3,
        },
      ],
    }
  end

  let(:updated_green_deal_plan_request_body) do
    {
      greenDealPlanId: "ABC123456DEF",
      startDate: "2020-02-28",
      endDate: "2030-03-28",
      providerDetails: {
        name: "The Bank", telephone: "0800 0000000", email: "lender@example.com"
      },
      interest: { rate: 12.3, fixed: true },
      chargeUplift: { amount: 1.25, date: "2025-03-29" },
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
          fuelCode: "LPG",
          fuelSaving: 9000.1,
          standingChargeFraction: -0.3,
        },
      ],
    }
  end

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
  end

  describe "update a Green Deal Plan" do
    context "when unauthenticated" do
      it "returns status 401" do
        update_green_deal_plan plan_id: "AD0000002312",
                               accepted_responses: [401],
                               authenticate: false
      end
    end

    context "when unauthorised" do
      it "returns status 403" do
        update_green_deal_plan plan_id: "AD0000002312",
                               accepted_responses: [403],
                               scopes: %w[wrong:scope]
      end
    end

    context "when plan does not exist" do
      it "returns status 404" do
        update_green_deal_plan plan_id: "AD0000002312",
                               body: valid_green_deal_plan_request_body,
                               accepted_responses: [404]
      end
    end

    context "when a plan does exist" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(
          update_green_deal_plan(
            plan_id: "ABC123456DEF", body: updated_green_deal_plan_request_body,
          ).body,
          symbolize_names: true,
        )
      end

      before do
        add_assessor scheme_id,
                     "SPEC000000",
                     AssessorStub.new.fetch_request_body(
                       domesticRdSap: "ACTIVE",
                     )

        lodge_assessment assessment_body: valid_rdsap_xml,
                         auth_data: { scheme_ids: [scheme_id] }

        add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                            body: valid_green_deal_plan_request_body
      end

      it "returns the expected response" do
        expect(response[:data]).to eq(
          {
            greenDealPlanId: "ABC123456DEF",
            startDate: "2020-02-28",
            endDate: "2030-03-28",
            providerDetails: {
              name: "The Bank",
              telephone: "0800 0000000",
              email: "lender@example.com",
            },
            interest: { rate: 12.3, fixed: true },
            chargeUplift: { amount: 1.25, date: "2025-03-29" },
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
                fuelCode: "LPG",
                fuelSaving: 9000.1,
                standingChargeFraction: -0.3,
              },
            ],
          },
        )
      end

      context "with a different plan ID" do
        let(:response) do
          JSON.parse(
            update_green_deal_plan(
              plan_id: "ABC123456DEF",
              body: updated_green_deal_plan_request_body,
              accepted_responses: [400],
            ).body,
            symbolize_names: true,
          )
        end

        before do
          updated_green_deal_plan_request_body[:greenDealPlanId] =
            "ABMISMATCH12"
        end

        it "returns the expected error response" do
          expect(
            response[:errors][0][:title],
          ).to eq "Green Deal Plan ID does not match"
        end
      end
    end
  end
end
