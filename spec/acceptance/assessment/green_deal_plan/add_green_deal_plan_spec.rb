# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlan:AddGreenDealPlan", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:valid_green_deal_plan_request_body) do
    GreenDealPlanStub.new.request_body
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:valid_sap_xml) { Samples.xml "SAP-Schema-18.0.0" }

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
                            body: valid_green_deal_plan_request_body,
                            accepted_responses: [404]
      end
    end

    context "when an assessment does exist" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(
          add_green_deal_plan(
            assessment_id: "0000-0000-0000-0000-0000",
            body: valid_green_deal_plan_request_body,
          ).body,
          symbolize_names: true,
        )
      end

      let(:expected_response) do
        [
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
              rate: "12.3",
              fixed: true,
            },
            chargeUplift: {
              amount: "1.25",
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
                         accepted_responses: [201],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         }
      end

      it "returns the expected response" do
        expect(response[:data]).to eq expected_response[0]
      end

      context "with a Green Deal Plan" do
        let(:green_deal_plan_id_column) do
          ActiveRecord::Base.connection.exec_query <<-SQL
            SELECT green_deal_plan_id
            FROM green_deal_assessments
            WHERE assessment_id = '0000-0000-0000-0000-0000'
          SQL
        end

        let(:response) do
          JSON.parse(
            fetch_assessment_summary("0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )
        end

        before do
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                              body: valid_green_deal_plan_request_body,
                              accepted_responses: [201]
        end

        it "returns the expected Green Deal Plan ID from Green Deal assessments table" do
          expect(
            green_deal_plan_id_column.entries.first["green_deal_plan_id"],
          ).to eq "ABC123456DEF"
        end

        it "returns the expected Green Deal Plan from assessment" do
          expected_response[0][:interest][:rate] = "12.3"
          expected_response[0][:chargeUplift][:amount] = "1.25"

          expect(response[:data][:greenDealPlan]).to eq expected_response
        end

        it "can handle more than one green deal plan" do
          special_valid_green_deal_plan_request_body =
            valid_green_deal_plan_request_body

          special_valid_green_deal_plan_request_body[:greenDealPlanId] =
            "SECONDGREEND"

          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                              body: special_valid_green_deal_plan_request_body,
                              accepted_responses: [201]

          expected_response[0][:interest][:rate] = "12.3"
          expected_response[0][:chargeUplift][:amount] = "1.25"
          expected_response[1] = expected_response[0].dup
          expected_response[1][:greenDealPlanId] = "SECONDGREEND"

          expect(response[:data][:greenDealPlan]).to eq expected_response
        end
      end

      context "with an invalid Green Deal Plan ID" do
        let(:response) do
          JSON.parse(
            add_green_deal_plan(
              assessment_id: "0000-0000-0000-0000-0000",
              body: valid_green_deal_plan_request_body,
              accepted_responses: [400],
            ).body,
            symbolize_names: true,
          )
        end

        before do
          valid_green_deal_plan_request_body[:greenDealPlanId] = "AB_000000012"
        end

        it "returns the expected error response" do
          expect(
            response[:errors][0][:title],
          ).to eq "The property '#/greenDealPlanId' value \"AB_000000012\" did not match the regex '^[a-zA-Z0-9]{12}$'"
        end
      end

      context "with the same Green Deal Plan ID" do
        let(:response) do
          JSON.parse(
            add_green_deal_plan(
              assessment_id: "0000-0000-0000-0000-0000",
              body: valid_green_deal_plan_request_body,
              accepted_responses: [409],
            ).body,
            symbolize_names: true,
          )
        end

        before do
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                              body: valid_green_deal_plan_request_body,
                              accepted_responses: [201]
        end

        it "returns the expected error response" do
          expect(
            response[:errors][0][:title],
          ).to eq "Green Deal Plan ID already exists"
        end
      end

      context "with a cancelled assessment" do
        before do
          update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                                   assessment_status_body: {
                                     "status": "CANCELLED",
                                   },
                                   accepted_responses: [200],
                                   auth_data: {
                                     scheme_ids: [scheme_id],
                                   }
        end

        it "returns status 410" do
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                              body: valid_green_deal_plan_request_body,
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
                                   auth_data: {
                                     scheme_ids: [scheme_id],
                                   }
        end

        it "returns status 410" do
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                              body: valid_green_deal_plan_request_body,
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
                           auth_data: {
                             scheme_ids: [scheme_id],
                           },
                           schema_name: "SAP-Schema-18.0.0"
        end

        it "returns status 400" do
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0001",
                              body: valid_green_deal_plan_request_body,
                              accepted_responses: [400]
        end
      end

      context "when missing required fields" do
        let(:assessment) { Nokogiri.XML valid_rdsap_xml }
        let(:assessment_id) { assessment.at "RRN" }

        let(:response) do
          JSON.parse(
            add_green_deal_plan(
              assessment_id: "0000-0000-0000-0000-0001",
              body: valid_green_deal_plan_request_body,
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
            add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                                body: incorrect_fuel_codes,
                                accepted_responses: [400]

          expect(
            response.body,
          ).to include "One of [LPG, SOLAR] is not a valid fuel code"
        end
      end
    end

    context "when a Green Deal Plan is added to an expired RdSAP assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_rdsap_xml }
      let(:assessment_date) { doc.at("Registration-Date") }

      before do
        add_assessor scheme_id,
                     "SPEC000000",
                     AssessorStub.new.fetch_request_body(
                       domesticRdSap: "ACTIVE",
                     )

        assessment_date.children = Date.today.prev_year(11).strftime("%Y-%m-%d")

        lodge_assessment assessment_body: doc.to_xml,
                         accepted_responses: [201],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         },
                         override: true
      end

      it "returns status 410 with the correct error message" do
        response =
          JSON.parse(
            add_green_deal_plan(
              assessment_id: "0000-0000-0000-0000-0000",
              body: valid_green_deal_plan_request_body,
              accepted_responses: [410],
            ).body,
          )

        expect(response["errors"][0]["title"]).to eq("Assessment has expired")
      end
    end
  end
end
