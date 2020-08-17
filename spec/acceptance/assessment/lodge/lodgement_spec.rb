# frozen_string_literal: true

describe "Acceptance::Assessment::Lodge" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      domesticRdSap: "ACTIVE", nonDomesticNos3: "ACTIVE",
    )
  end

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
  end

  let(:valid_cepc_rr_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc+rr.xml"
  end

  context "when lodging an energy assessment (post)" do
    it "rejects an assessment with a schema that does not exist" do
      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [400],
        schema_name: "MakeupSAP-20.0.0",
      )
    end

    context "when an assessor is not registered" do
      it "returns status 400" do
        lodge_assessment(
          assessment_body: valid_rdsap_xml, accepted_responses: [400],
        )
      end

      it "returns status 400 with the correct error response" do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_body: valid_rdsap_xml, accepted_responses: [400],
            ).body,
          )

        expect(response["errors"][0]["title"]).to eq(
          "Assessor is not registered.",
        )
      end
    end

    it "returns 401 with no authentication" do
      lodge_assessment(
        assessment_body: "body", accepted_responses: [401], authenticate: false,
      )
    end

    it "returns 403 with incorrect scopes" do
      lodge_assessment(
        assessment_body: "body",
        accepted_responses: [403],
        auth_data: { scheme_ids: {} },
        scopes: %w[wrong:scope],
      )
    end

    it "returns 403 if it is being lodged by the wrong scheme" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)
      different_scheme_id = add_scheme_and_get_id("BADSCHEME")

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [403],
        auth_data: { scheme_ids: [different_scheme_id] },
      )
    end

    it "returns the correct response" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_rdsap_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
          ).body,
          symbolize_names: true,
        )

      expect(response).to eq(
        {
          data: { assessments: %w[0000-0000-0000-0000-0000] },
          meta: {
            links: {
              assessments: %w[/api/assessments/0000-0000-0000-0000-0000],
            },
          },
        },
      )
    end

    context "when schema is not supported" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_rdsap_xml }

      before do
        add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)
      end

      it "returns status 400" do
        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [400],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "unsupported",
        )
      end

      it "returns the correct error message" do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_body: doc.to_xml,
              accepted_responses: [400],
              auth_data: { scheme_ids: [scheme_id] },
              schema_name: "unsupported",
            ).body,
          )

        expect(response["errors"][0]["title"]).to eq("Schema is not supported.")
      end
    end

    context "when saving an assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_rdsap_xml }
      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)
      end

      context "when an assessment already exists with the same assessment id" do
        it "returns status 409" do
          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
          )

          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [409],
            auth_data: { scheme_ids: [scheme_id] },
          )
        end
      end
    end

    context "when rejecting an assessment" do
      it "rejects an assessment with an incorrect element" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

        doc = Nokogiri.XML valid_rdsap_xml

        scheme_assessor_id = doc.at("Address")
        scheme_assessor_id.children = "<Postcode>invalid</Postcode>"

        response_body =
          JSON.parse(
            lodge_assessment(
              assessment_body: doc.to_xml, accepted_responses: [400],
            ).body,
          )

        expect(
          response_body["errors"][0]["title"],
        ).to include "This element is not expected."
      end

      it "rejects an assessment with invalid XML" do
        xml = valid_rdsap_xml

        xml = xml.gsub("<Energy-Assessment>", "<Energy-Assessment")

        response_body =
          JSON.parse(
            lodge_assessment(assessment_body: xml, accepted_responses: [400])
              .body,
          )

        expect(
          response_body["errors"][0]["title"],
        ).to include "Invalid attribute name: <<Property-Summary>"
      end
    end
  end

  context "when an unauthenticated migration request is made" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:response) do
      JSON.parse(
        lodge_assessment(
          assessment_body: valid_rdsap_xml,
          accepted_responses: [403],
          auth_data: { scheme_ids: [scheme_id] },
          migrated: true,
        ).body,
        symbolize_names: true,
      )
    end

    before { add_assessor scheme_id, "SPEC000000", valid_assessor_request_body }

    it "shows the correct error response" do
      expect(response).to eq(
        {
          errors: [
            {
              code: "UNAUTHORISED",
              title: "You are not authorised to perform this request",
            },
          ],
        },
      )
    end
  end

  context "when lodging an energy assessment" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:migrated_column) do
      ActiveRecord::Base.connection.execute(
        "SELECT migrated FROM assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
      )
    end

    before { add_assessor scheme_id, "SPEC000000", valid_assessor_request_body }

    context "with migrated parameter" do
      before do
        lodge_assessment assessment_body: valid_rdsap_xml,
                         accepted_responses: [201],
                         scopes: %w[assessment:lodge migrate:assessment],
                         auth_data: { scheme_ids: [scheme_id] },
                         migrated: true
      end

      it "should be true in migrated column" do
        expect(migrated_column.entries.first["migrated"]).to be_truthy
      end

      context "when migrating the same assessment ID" do
        before do
          lodge_assessment assessment_body: valid_rdsap_xml,
                           accepted_responses: [201],
                           scopes: %w[assessment:lodge migrate:assessment],
                           auth_data: { scheme_ids: [scheme_id] },
                           migrated: true
        end

        it "should be true in migrated column" do
          expect(migrated_column.entries.first["migrated"]).to be_truthy
        end
      end

      context "with an associated Green Deal Plan" do
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
              { fuelCode: "39", fuelSaving: 23_253, standingChargeFraction: 0 },
              {
                fuelCode: "40", fuelSaving: -6331, standingChargeFraction: -0.9
              },
              { fuelCode: "41", fuelSaving: -15_561, standingChargeFraction: 0 },
            ],
            estimatedSavings: 1566,
          }
        end

        let(:response) do
          JSON.parse fetch_assessment_summary("0000-0000-0000-0000-0000").body,
                     symbolize_names: true
        end

        before do
          add_green_deal_plan assessment_id: "0000-0000-0000-0000-0000",
                              body: valid_green_deal_plan_request_body

          lodge_assessment assessment_body: valid_rdsap_xml,
                           scopes: %w[assessment:lodge migrate:assessment],
                           auth_data: { scheme_ids: [scheme_id] },
                           migrated: true
        end

        it "should be true in migrated column" do
          expect(migrated_column.entries.first["migrated"]).to be_truthy
        end

        it "returns the expected associated Green Deal Plan" do
          expect(
            response[:data][:greenDealPlan][:greenDealPlanId],
          ).to eq "ABC123456DEF"
        end
      end

      context "when migrating an assessment submitted by an assessor who is now unqualified" do
        let(:rdsap_xml) do
          add_assessor scheme_id,
                       "UNQU000000",
                       AssessorStub.new.fetch_request_body(
                         domesticRdSap: "INACTIVE",
                       )

          xml = Nokogiri.XML valid_rdsap_xml

          xml.css("Certificate-Number").children.first.content = "UNQU000000"

          xml.to_s
        end

        it "should be true in migrated column" do
          lodge_assessment assessment_body: rdsap_xml,
                           accepted_responses: [201],
                           scopes: %w[assessment:lodge migrate:assessment],
                           auth_data: { scheme_ids: [scheme_id] },
                           migrated: true
        end
      end
    end

    context "without migrated parameter" do
      before do
        lodge_assessment assessment_body: valid_rdsap_xml,
                         accepted_responses: [201],
                         auth_data: { scheme_ids: [scheme_id] }
      end

      it "shows false in the migrated column" do
        expect(migrated_column.entries.first["migrated"]).to be_falsey
      end
    end
  end

  context "when lodging two energy assessments" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:response) do
      JSON.parse(
        lodge_assessment(
          assessment_body: valid_cepc_rr_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-8.0.0",
        ).body,
        symbolize_names: true,
      )
    end

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   AssessorStub.new.fetch_request_body(
                     nonDomesticNos3: "ACTIVE",
                   )
    end

    it "returns the correct response" do
      expect(response).to eq(
        {
          data: {
            assessments: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
          },
          meta: {
            links: {
              assessments: %w[
                /api/assessments/0000-0000-0000-0000-0000
                /api/assessments/0000-0000-0000-0000-0001
              ],
            },
          },
        },
      )
    end
  end

  context "when lodging an assessment with the override flag set to true" do
    let(:valid_cepc_xml) do
      File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
    end

    let(:cepc_xml_doc) do
      cepc_xml_doc = Nokogiri.XML(valid_cepc_xml)
      cepc_xml_doc
    end

    it "will lodge the assessment and log the events to the overidden_lodgement_events table" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      cepc_xml_doc.at("//CEPC:Registration-Date").children = "2030-05-04"

      lodge_assessment(
        assessment_body: cepc_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
        override: true,
      )

      overidden_lodgement_event =
        ActiveRecord::Base.connection.execute(
          "SELECT * FROM overidden_lodgement_events WHERE assessment_id = '0000-0000-0000-0000-0000'",
        ).first

      expect(overidden_lodgement_event["assessment_id"]).to eq(
        "0000-0000-0000-0000-0000",
      )
      expect(overidden_lodgement_event["rule_triggers"]).to eq(
        "[{\"code\": \"DATES_CANT_BE_IN_FUTURE\", \"title\": \"Inspection-Date\\\", \\\"Registration-Date\\\", \\\"Issue-Date\\\", \\\"Effective-Date\\\", \\\"OR-Availability-Date\\\", \\\"Start-Date\\\" and \\\"OR-Assessment-Start-Date\\\" must not be in the future\"}]",
      )
    end
  end
end
