# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlan:UpdateGreenDealPlan" do
  include RSpecAssessorServiceMixin

  PUT_SCHEMA = Controller::GreenDealPlanController::SCHEMA
  FIELDS = PUT_SCHEMA[:required]
  PROVIDER_DETAILS_FIELDS = PUT_SCHEMA[:properties][:providerDetails][:required]
  INTEREST_FIELDS = PUT_SCHEMA[:properties][:interest][:required]
  CHARGES_FIELDS = PUT_SCHEMA[:properties][:charges][:items][:required]
  SAVINGS_FIELDS = PUT_SCHEMA[:properties][:savings][:items][:required]

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

  def green_deal_plan_without(key, root = nil)
    if root
      if valid_green_deal_plan_request_body[root].is_a? Array
        valid_green_deal_plan_request_body[root].each do |hashes|
          return hashes.tap { |hash| hash.delete key }
        end
      end

      valid_green_deal_plan_request_body[root].tap { |field| field.delete key }
    end

    valid_green_deal_plan_request_body.tap { |field| field.delete key }
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

      context "when missing required fields" do
        let(:assessment) { Nokogiri.XML valid_rdsap_xml }
        let(:assessment_id) { assessment.at "RRN" }

        let(:response) do
          JSON.parse(
            update_green_deal_plan(
              plan_id: "ABC123456DEF",
              body: valid_green_deal_plan_request_body,
              accepted_responses: [422],
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
                           auth_data: { scheme_ids: [scheme_id] }
        end

        FIELDS.each do |field|
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
        PROVIDER_DETAILS_FIELDS.each do |field|
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

        INTEREST_FIELDS.each do |field|
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

        CHARGES_FIELDS.each do |field|
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

        SAVINGS_FIELDS.each do |field|
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
    end
  end
end
