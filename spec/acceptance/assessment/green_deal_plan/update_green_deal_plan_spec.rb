# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlan:UpdateGreenDealPlan", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

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
        { fuelCode: "39", fuelSaving: 23_253, standingChargeFraction: 0 },
        { fuelCode: "40", fuelSaving: -6331, standingChargeFraction: -0.9 },
        { fuelCode: "41", fuelSaving: -15_561, standingChargeFraction: 0 },
      ],
    }
  end

  let(:updated_green_deal_plan_request_body) do
    {
      greenDealPlanId: "ABC123456DEF",
      startDate: "2020-02-28",
      endDate: "2030-03-30",
      providerDetails: {
        name: "The New Bank",
        telephone: "0900 0000000",
        email: "lender@example.io",
      },
      interest: {
        rate: 12.5,
        fixed: false,
      },
      chargeUplift: {
        amount: 0.25,
        date: "2025-04-29",
      },
      ccaRegulated: false,
      structureChanged: true,
      measuresRemoved: true,
      measures: [
        {
          sequence: 0,
          measureType: "Cavity Wall",
          product: "ColdHome lagging stuff (TM)",
          repaidDate: "2025-04-29",
        },
      ],
      charges: [
        {
          sequence: 0,
          startDate: "2020-04-29",
          endDate: "2030-04-29",
          dailyCharge: 0.35,
        },
      ],
      savings: [
        { fuelCode: "39", fuelSaving: 23_253, standingChargeFraction: 0 },
        { fuelCode: "40", fuelSaving: -6331, standingChargeFraction: -0.9 },
        { fuelCode: "41", fuelSaving: -15_561, standingChargeFraction: 0 },
      ],
    }
  end

  def green_deal_plan_without(key, root = nil)
    if root
      if updated_green_deal_plan_request_body[root].is_a? Array
        updated_green_deal_plan_request_body[root].each do |hashes|
          return hashes.tap { |hash| hash.delete key }
        end
      end

      updated_green_deal_plan_request_body[root].tap do |field|
        field.delete key
      end
    end

    updated_green_deal_plan_request_body.tap { |field| field.delete key }
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

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
            plan_id: "ABC123456DEF",
            body: updated_green_deal_plan_request_body,
          ).body,
          symbolize_names: true,
        )
      end

      let(:expected_response) do
        [
          {
            greenDealPlanId: "ABC123456DEF",
            startDate: "2020-02-28",
            endDate: "2030-03-30",
            providerDetails: {
              name: "The New Bank",
              telephone: "0900 0000000",
              email: "lender@example.io",
            },
            interest: {
              rate: 12.5,
              fixed: false,
            },
            chargeUplift: {
              amount: 0.25,
              date: "2025-04-29",
            },
            ccaRegulated: false,
            structureChanged: true,
            measuresRemoved: true,
            measures: [
              {
                sequence: 0,
                measureType: "Cavity Wall",
                product: "ColdHome lagging stuff (TM)",
                repaidDate: "2025-04-29",
              },
            ],
            charges: [
              {
                sequence: 0,
                startDate: "2020-04-29",
                endDate: "2030-04-29",
                dailyCharge: 0.35,
              },
            ],
            savings: [
              { fuelCode: "39", fuelSaving: 23_253, standingChargeFraction: 0 },
              {
                fuelCode: "40",
                fuelSaving: -6331,
                standingChargeFraction: -0.9,
              },
              { fuelCode: "41", fuelSaving: -15_561, standingChargeFraction: 0 },
            ],
            estimatedSavings: 1566,
          },
        ]
      end

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

      it "returns the expected response" do
        expect(response[:data]).to eq expected_response.first
      end

      context "when updating a Green Deal Plan" do
        let(:response) do
          JSON.parse(
            fetch_assessment_summary("0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )
        end

        before do
          update_green_deal_plan plan_id: "ABC123456DEF",
                                 body: updated_green_deal_plan_request_body
        end

        it "returns the expected Green Deal Plan from assessment" do
          expected_response[0][:interest][:rate] = "12.5"
          expected_response[0][:chargeUplift][:amount] = "0.25"

          expect(response[:data][:greenDealPlan]).to eq expected_response
        end
      end

      context "with a different plan ID" do
        let(:response) do
          JSON.parse(
            update_green_deal_plan(
              plan_id: "ABC123456DEF",
              body: updated_green_deal_plan_request_body,
              accepted_responses: [409],
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

      context "when missing required fields" do
        let(:assessment) { Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0" }
        let(:assessment_id) { assessment.at "RRN" }

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
          add_assessor scheme_id,
                       "SPEC000000",
                       AssessorStub.new.fetch_request_body(
                         domesticRdSap: "ACTIVE",
                       )

          assessment_id.children = "0000-0000-0000-0000-0001"

          lodge_assessment assessment_body: assessment.to_xml,
                           accepted_responses: [201],
                           auth_data: {
                             scheme_ids: [scheme_id],
                           }
        end

        GREEN_DEAL_PLAN_SCHEMA[:required].each do |field|
          context "with missing #{field}" do
            before { green_deal_plan_without field.to_sym }

            it "returns the expected error response" do
              expect(response[:errors][0][:title]).to eq(
                "The property '#/' did not contain a required property of '#{
                  field
                }'",
              )
            end
          end
        end

        GREEN_DEAL_PLAN_SCHEMA[:properties][:providerDetails][:required]
          .each do |field|
          context "with missing provider detail #{field}" do
            before { green_deal_plan_without field.to_sym, :providerDetails }

            it "returns the expected error response" do
              expect(response[:errors][0][:title]).to eq(
                "The property '#/providerDetails' did not contain a required property of '#{
                  field
                }'",
              )
            end
          end
        end

        GREEN_DEAL_PLAN_SCHEMA[:properties][:interest][:required]
          .each do |field|
          context "with missing interest #{field}" do
            before { green_deal_plan_without field.to_sym, :interest }

            it "returns the expected error response" do
              expect(response[:errors][0][:title]).to eq(
                "The property '#/interest' did not contain a required property of '#{
                  field
                }'",
              )
            end
          end
        end

        context "with missing chargeUplift amount" do
          before { green_deal_plan_without :amount, :chargeUplift }

          it "returns the expected error response" do
            expect(response[:errors][0][:title]).to eq(
              "The property '#/chargeUplift' did not contain a required property of 'amount'",
            )
          end
        end

        context "with missing measures product" do
          before { green_deal_plan_without :product, :measures }

          it "returns the expected error response" do
            expect(response[:errors][0][:title]).to eq(
              "The property '#/measures/0' did not contain a required property of 'product'",
            )
          end
        end

        GREEN_DEAL_PLAN_SCHEMA[:properties][:charges][:items][:required]
          .each do |field|
          context "with missing interest #{field}" do
            before { green_deal_plan_without field.to_sym, :charges }

            it "returns the expected error response" do
              expect(response[:errors][0][:title]).to eq(
                "The property '#/charges/0' did not contain a required property of '#{
                  field
                }'",
              )
            end
          end
        end

        GREEN_DEAL_PLAN_SCHEMA[:properties][:savings][:items][:required]
          .each do |field|
          context "with missing interest #{field}" do
            before { green_deal_plan_without field.to_sym, :savings }

            it "returns the expected error response" do
              expect(response[:errors][0][:title]).to eq(
                "The property '#/savings/0' did not contain a required property of '#{
                  field
                }'",
              )
            end
          end
        end
      end

      context "when the fuel codes in the savings are invalid" do
        it "returns the expected error response" do
          incorrect_fuel_codes = valid_green_deal_plan_request_body.dup
          incorrect_fuel_codes[:savings] = [
            { fuelCode: "LPG", fuelSaving: 23_253, standingChargeFraction: 0 },
            { fuelCode: "SOLAR", fuelSaving: 23_253, standingChargeFraction: 0 },
          ]

          response =
            update_green_deal_plan plan_id: "ABC123456DEF",
                                   body: incorrect_fuel_codes,
                                   accepted_responses: [400]

          expect(
            response.body,
          ).to include "One of [LPG, SOLAR] is not a valid fuel code"
        end
      end
    end
  end
end
