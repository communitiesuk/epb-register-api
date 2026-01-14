# frozen_string_literal: true

require "date"

describe "Acceptance::ScotlandCertificateSummary", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  it "returns 404 for an assessment that doesnt exist" do
    expect(fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000", accepted_responses: [404]).status).to eq(404)
  end

  it "returns 400 for an assessment id that is not valid" do
    expect(fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000%23", accepted_responses: [400]).status).to eq(400)
  end

  describe "security scenarios" do
    it "rejects a request that is not authenticated" do
      expect(fetch_scottish_certificate_summary(id: "123", accepted_responses: [401], should_authenticate: false).status).to eq(401)
    end

    it "rejects a request with the wrong scopes" do
      expect(fetch_scottish_certificate_summary(id: "124", accepted_responses: [403], scopes: %w[wrong:scope]).status).to eq(403)
    end
  end

  context "when requesting Scottish assessments" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:assessor) do
      AssessorStub.new.fetch_request_body(
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
      )
    end

    before do
      add_countries
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: assessor)
    end

    context "when a certificate has been cancelled" do
      it "raises the AssessmentGone Error" do
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-S-19.0")
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-19.0",
          migrated: true,
        )
        ActiveRecord::Base.connection.exec_query("UPDATE scotland.assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
        expect(fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000", accepted_responses: [410]).status).to eq(410)
      end
    end

    context "when requesting a RdSAP assessment" do
      let(:related_assessment) { [] }
      let(:green_deal_plan) { [] }
      let(:superseded_by) { nil }
      let(:date_of_expiry) { "2030-05-03" }
      let(:date_of_registration) { "2020-05-04" }
      let(:assessment_id) { "0000-0000-0000-0000-0000" }

      let(:expected_response) do
        {
          addendum: nil,
          address: { addressLine1: "1 Some Street", addressLine2: "", addressLine3: "", addressLine4: nil, postcode: "FK1 1XE", town: "Newkirk" },
          addressId: "RRN-0000-0000-0000-0000-0000",
          assessmentId: "0000-0000-0000-0000-0000",
          assessor:
              {
                contactDetails: { email: "a@b.c", telephoneNumber: "0555 497 2848" },
                firstName: "Someone",
                lastName: "Person",
                registeredBy: { name: "test scheme", schemeId: scheme_id },
                schemeAssessorId: "SPEC000000",
              },
          countryName: "Unknown",
          currentCarbonEmission: "1.7",
          currentEnergyEfficiencyBand: "c",
          currentEnergyEfficiencyRating: 79,
          dateOfAssessment: "2023-06-27",
          dateOfExpiry: "2033-06-26",
          dateOfRegistration: "2023-06-27",
          dwellingType: "Top-floor flat",
          electricitySmartMeterPresent: nil,
          environmentalImpactCurrent: 80,
          environmentalImpactPotential: 80,
          estimatedEnergyCost: "933.00",
          gasSmartMeterPresent: nil,
          greenDealPlan: [],
          heatDemand: { currentSpaceHeatingDemand: 3865, currentWaterHeatingDemand: 1955 },
          heatingCostCurrent: "585",
          heatingCostPotential: "585",
          hotWaterCostCurrent: "226",
          hotWaterCostPotential: "226",
          lightingCostCurrent: "122",
          lightingCostPotential: "122",
          lzcEnergySources: nil,
          optOut: false,
          potentialCarbonEmission: "1.7",
          potentialEnergyEfficiencyBand: "c",
          potentialEnergyEfficiencyRating: 79,
          potentialEnergySaving: "0.00",
          primaryEnergyUse: "145",
          propertySummary:
              [
                { description: "Timber frame, as built, insulated (assumed)", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "wall" },
                { description: "Solid brick, as built, insulated (assumed)", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "wall" },
                { description: "Pitched, insulated (assumed)", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "roof" },
                { description: "(another dwelling below)", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "floor" },
                { description: "Fully double glazed", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "window" },
                { description: "Boiler and radiators, mains gas", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "main_heating" },
                { description: "Programmer, room thermostat and TRVs", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "main_heating_controls" },
                { description: "From main system", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "hot_water" },
                { description: "Low energy lighting in all fixed outlets", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "lighting" },
                { description: "None", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "secondary_heating" },
              ],
          recommendedImprovements: [],
          relatedAssessments: [],
          relatedPartyDisclosureNumber: 1,
          relatedPartyDisclosureText: nil,
          status: "ENTERED",
          supersededBy: nil,
          totalFloorArea: "66.0",
          typeOfAssessment: "RdSAP",
        }
      end

      before do
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-S-19.0")
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-19.0",
          migrated: true,
        )
      end

      it "returns the expected response" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )
        expect(response[:data]).to eq(expected_response)
      end

      context "when there is a related assessment" do
        let(:related_assessment_ids) do
          %w[
            0000-0000-0000-0000-0001
            0000-0000-0000-0000-0003
            0000-0000-0000-0000-0042
          ]
        end
        let(:related_assessment) do
          [{
            assessmentId: "0000-0000-0000-0000-0042",
            assessmentStatus: "ENTERED",
            assessmentType: "RdSAP",
            assessmentExpiryDate: "2033-06-26",
            optOut: false,
          },
           {
             assessmentId: "0000-0000-0000-0000-0003",
             assessmentStatus: "ENTERED",
             assessmentType: "RdSAP",
             assessmentExpiryDate: "2033-06-26",
             optOut: false,
           }]
        end
        let(:superseded_by) { "0000-0000-0000-0000-0042" }

        before do
          schema = "RdSAP-Schema-S-19.0"
          xml = Nokogiri.XML Samples.xml(schema)
          xml.at("UPRN").children.to_s
          related_assessment_ids.each do |assessment_id|
            xml.at("RRN").children = assessment_id
            call_lodge_assessment scheme_id:, schema_name: schema, xml_document: xml, migrated: true
          end
        end

        it "returns the expected response" do
          ActiveRecord::Base.connection.exec_query("UPDATE scotland.assessments_address_id SET address_id = 'RRN-0000-0000-0000-0000-0001' WHERE assessment_id IN ( '0000-0000-0000-0000-0001', '0000-0000-0000-0000-0003', '0000-0000-0000-0000-0042') ")

          response =
            JSON.parse(
              fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0001").body,
              symbolize_names: true,
            )
          expect(response[:data][:relatedAssessments]).to eq(related_assessment)
        end
      end

      # context "when a green deal is attached" do
      #   let(:assessment_id) { "0000-0000-0000-0000-1111" }
      #   let(:green_deal_plan) do
      #     [{ greenDealPlanId: "ABC654321DEF",
      #        startDate: "2020-01-30",
      #        endDate: "2030-02-28",
      #        providerDetails: { name: "The Bank",
      #                           telephone: "0800 0000000",
      #                           email: "lender@example.com" },
      #
      #        interest: { rate: "12.3",
      #                    fixed: true },
      #        chargeUplift: { amount: "1.25",
      #                        date: "2025-03-29" },
      #        ccaRegulated: true,
      #        structureChanged: false,
      #        measuresRemoved: false,
      #        measures: [{ product: "WarmHome lagging stuff (TM)",
      #                     sequence: 0,
      #                     repaidDate: "2025-03-29",
      #                     measureType: "Loft insulation" }],
      #        charges: [{ endDate: "2030-03-29",
      #                    sequence: 0,
      #                    startDate: "2020-03-29",
      #                    dailyCharge: 0.34 }],
      #        savings: [{ fuelCode: "39",
      #                    fuelSaving: 23_253,
      #                    standingChargeFraction: 0 },
      #                  { fuelCode: "40",
      #                    fuelSaving: -6331,
      #                    standingChargeFraction: -0.9 },
      #                  { fuelCode: "41",
      #                    fuelSaving: -15_561,
      #                    standingChargeFraction: 0 }],
      #        estimatedSavings: 1566 }]
      #   end
      #   let(:related_assessment) do
      #     [{
      #       assessmentId: "0000-0000-0000-0000-0000",
      #       assessmentStatus: "ENTERED",
      #       assessmentType: "RdSAP",
      #       assessmentExpiryDate: "2030-05-03",
      #       optOut: false,
      #     }]
      #   end
      #   let(:date_of_expiry) { "2034-10-09" }
      #   let(:date_of_registration) { "2024-10-10" }
      #
      #   before do
      #     load_green_deal_data
      #     add_assessment_with_green_deal(
      #       type: "RdSAP",
      #       assessment_id: "0000-0000-0000-0000-1111",
      #       registration_date: "2024-10-10",
      #       green_deal_plan_id: "ABC654321DEF",
      #     )
      #   end
      #
      #   it "returns the green deal data" do
      #     response =
      #       JSON.parse(
      #         fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-1111").body,
      #         symbolize_names: true,
      #       )
      #
      #     # the interest rate and charge uplift amount are big decimal values which
      #     # gets decoded to a string with the .to_json method
      #     expect(response).to eq(expected_response)
      #   end
      # end
    end

    context "when requesting a SAP assessment" do
      let(:expected_response) do
        { data:
            { addendum: nil,
              address: { addressLine1: "1 LOVELY ROAD", addressLine2: "NICE ESTATE", addressLine3: "", addressLine4: nil, postcode: "EH1 2NG", town: "TOWN" },
              addressId: "RRN-0000-0000-0000-0000-0067",
              assessmentId: "0000-0000-0000-0000-0067",
              assessor: {
                contactDetails: { email: "a@b.c", telephoneNumber: "111222333" },
                firstName: "Someone",
                lastName: "Person",
                registeredBy: { name: "test scheme", schemeId: scheme_id },
                schemeAssessorId: "SPEC000000",
              },
              countryName: "Unknown",
              currentCarbonEmission: "2.2",
              currentEnergyEfficiencyBand: "b",
              currentEnergyEfficiencyRating: 91,
              dateOfAssessment: "2024-11-21",
              dateOfExpiry: "2034-11-20",
              dateOfRegistration: "2024-11-21",
              dwellingType: "Detached house",
              electricitySmartMeterPresent: true,
              environmentalImpactCurrent: 88,
              environmentalImpactPotential: 88,
              estimatedEnergyCost: "837.00",
              gasSmartMeterPresent: true,
              heatDemand: { currentSpaceHeatingDemand: nil, currentWaterHeatingDemand: nil },
              heatingCostCurrent: "603",
              heatingCostPotential: "603",
              hotWaterCostCurrent: "152",
              hotWaterCostPotential: "152",
              lightingCostCurrent: "82",
              lightingCostPotential: "82",
              lzcEnergySources: [11],
              optOut: false,
              potentialCarbonEmission: "2.2",
              potentialEnergyEfficiencyBand: "b",
              potentialEnergyEfficiencyRating: 91,
              potentialEnergySaving: "0.00",
              primaryEnergyUse: "63",
              propertySummary:
                [
                  { description: "Average thermal transmittance 0.21 W/m²K", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "walls" },
                  { description: "Average thermal transmittance 0.14 W/m²K", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "roof" },
                  { description: "Average thermal transmittance 0.16 W/m²K", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "floor" },
                  { description: "High performance glazing", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "windows" },
                  { description: "Boiler and radiators, mains gas", energyEfficiencyRating: 5, environmentalEfficiencyRating: 4, name: "main_heating" },
                  { description: "Time and temperature zone control", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "main_heating_controls" },
                  { description: "None", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "secondary_heating" },
                  { description: "From main system", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "hot_water" },
                  { description: "Excelent lighting efficiency", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "lighting" },
                  { description: "Air permeability [AP50] = 4.0 m³/h.m² (as tested)", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "air_tightness" },
                ],
              recommendedImprovements: [],
              relatedAssessments: [],
              relatedPartyDisclosureNumber: 1,
              relatedPartyDisclosureText: nil,
              status: "ENTERED",
              supersededBy: nil,
              totalFloorArea: "184.0",
              typeOfAssessment: "SAP" },
          "meta": {} }
      end

      before do
        sap_schema = "SAP-Schema-S-19.0.0"
        sap_xml = Nokogiri.XML(Samples.xml(sap_schema))
        sap_xml.at("RRN").content = "0000-0000-0000-0000-0067"
        lodge_assessment(
          assessment_body: sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: sap_schema,
          migrated: true,
        )
      end

      it "returns Scottish SAP" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0067").body,
            symbolize_names: true,
          )
        expect(response).to eq(expected_response)
      end
    end

    context "when requesting a CEPC assessment" do
      before do
        cepc_xml = Nokogiri.XML Samples.xml("CEPC-S-7.1", "cepc")
        cepc_xml
          .xpath("//*[local-name() = 'RRN']")
          .each do |node|
          node.content = "0000-0000-0000-0002-0000"
        end
        lodge_assessment(
          assessment_body: cepc_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-S-7.1",
          migrated: true,
        )
      end

      it "raises a 400 error" do
        expect(fetch_scottish_certificate_summary(id: "0000-0000-0000-0002-0000", accepted_responses: [400]).status).to eq(400)
      end
    end
  end
end
