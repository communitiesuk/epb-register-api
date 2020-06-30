# frozen_string_literal: true

describe "Acceptance::LodgeRdSAPNIEnergyAssessment" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_rdsap_ni_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap-ni.xml"
  end

  context "when lodging a domestic energy assessment (post)" do
    context "when an assessor is inactive" do
      context "when unqualified for RdSAP" do
        it "returns status 400 with the correct error response" do
          scheme_id = add_scheme_and_get_id
          add_assessor(
            scheme_id,
            "SPEC000000",
            fetch_assessor_stub.fetch_request_body(domesticRdSap: "INACTIVE"),
          )

          response =
            JSON.parse(
              lodge_assessment(
                assessment_body: valid_rdsap_ni_xml,
                accepted_responses: [400],
                auth_data: { scheme_ids: [scheme_id] },
                schema_name: "RdSAP-Schema-NI-19.0",
              ).body,
            )

          expect(response["errors"][0]["title"]).to eq(
            "Assessor is not active.",
          )
        end
      end
    end

    it "returns status 201" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticRdSap: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_rdsap_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "RdSAP-Schema-NI-19.0",
      )
    end

    context "when saving a (RdSAP-NI) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_rdsap_ni_xml }
      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(domesticRdSap: "ACTIVE"),
        )
      end

      it "returns the data that was lodged" do
        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "RdSAP-Schema-NI-19.0",
        )

        expected_response = {
          "addressId" => "UPRN-000000000000",
          "addressLine1" => "1 Some Street",
          "addressLine2" => "",
          "addressLine3" => "",
          "addressLine4" => "",
          "tenure" => "1",
          "assessmentId" => "0000-0000-0000-0000-0000",
          "assessor" => {
            "contactDetails" => {
              "email" => "person@person.com",
              "telephoneNumber" => "010199991010101",
            },
            "dateOfBirth" => "1991-02-25",
            "firstName" => "Someone",
            "lastName" => "Person",
            "middleNames" => "Muddle",
            "address" => {},
            "companyDetails" => {},
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "ACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
              "gda" => "INACTIVE",
            },
            "registeredBy" => {
              "name" => "test scheme", "schemeId" => scheme_id
            },
            "schemeAssessorId" => "SPEC000000",
            "searchResultsComparisonPostcode" => "",
          },
          "currentCarbonEmission" => 2.4,
          "currentEnergyEfficiencyBand" => "e",
          "currentEnergyEfficiencyRating" => 50,
          "dateOfAssessment" => "2006-05-04",
          "dateOfExpiry" => "2016-05-04",
          "dateRegistered" => "2006-05-04",
          "dwellingType" => "Dwelling-Type0",
          "lightingCostCurrent" => 123.45,
          "heatingCostCurrent" => 365.98,
          "hotWaterCostCurrent" => 200.40,
          "lightingCostPotential" => 84.23,
          "heatingCostPotential" => 250.34,
          "hotWaterCostPotential" => 180.43,
          "heatDemand" => {
            "currentSpaceHeatingDemand" => 30.0,
            "currentWaterHeatingDemand" => 60.0,
            "impactOfCavityInsulation" => -12,
            "impactOfLoftInsulation" => -8,
            "impactOfSolidWallInsulation" => -16,
          },
          "optOut" => false,
          "postcode" => "A0 0AA",
          "potentialCarbonEmission" => 1.4,
          "potentialEnergyEfficiencyBand" => "e",
          "potentialEnergyEfficiencyRating" => 50,
          "recommendedImprovements" => [
            {
              "energyPerformanceRatingImprovement" => 50,
              "environmentalImpactRatingImprovement" => 50,
              "greenDealCategoryCode" => "1",
              "improvementCategory" => "6",
              "improvementCode" => "5",
              "improvementType" => "Z3",
              "improvementTitle" => nil,
              "improvementDescription" => nil,
              "indicativeCost" => "5",
              "sequence" => 0,
              "typicalSaving" => "0.0",
            },
            {
              "energyPerformanceRatingImprovement" => 60,
              "environmentalImpactRatingImprovement" => 64,
              "greenDealCategoryCode" => "3",
              "improvementCategory" => "2",
              "improvementCode" => "1",
              "improvementType" => "Z2",
              "improvementTitle" => nil,
              "improvementDescription" => nil,
              "indicativeCost" => "2",
              "sequence" => 1,
              "typicalSaving" => "0.1",
            },
          ],
          "totalFloorArea" => 10.0,
          "town" => "Post-Town1",
          "typeOfAssessment" => "RdSAP",
          "propertySummary" => [
            {
              "description" => "Description0",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "wall",
            },
            {
              "description" => "Description1",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "wall",
            },
            {
              "description" => "Description2",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "roof",
            },
            {
              "description" => "Description3",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "roof",
            },
            {
              "description" => "Description4",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "floor",
            },
            {
              "description" => "Description5",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "floor",
            },
            {
              "description" => "Description6",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "window",
            },
            {
              "description" => "Description7",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "main_heating",
            },
            {
              "description" => "Description8",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "main_heating",
            },
            {
              "description" => "Description9",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "main_heating_controls",
            },
            {
              "description" => "Description10",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "main_heating_controls",
            },
            {
              "description" => "Description11",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "hot_water",
            },
            {
              "description" => "Description12",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "lighting",
            },
            {
              "description" => "Description13",
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "secondary_heating",
            },
          ],
          "propertyAgeBand" => "K",
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => "Financial interest",
          "status" => "EXPIRED",
        }

        expect(response["data"]).to eq(expected_response)
      end

      context "when the assessment has a related party disclosure number" do
        it "returns the data that was lodged" do
          related_party_number_xml = doc.dup

          related_party_number_xml.at(
            "Related-Party-Disclosure-Text",
          ).replace "<Related-Party-Disclosure-Number>4</Related-Party-Disclosure-Number>"

          lodge_assessment assessment_body: related_party_number_xml.to_xml,
                           accepted_responses: [201],
                           auth_data: { scheme_ids: [scheme_id] },
                           schema_name: "RdSAP-Schema-NI-19.0"

          parsed_response =
            JSON.parse JSON.generate(response), symbolize_names: true

          expect(
            parsed_response.dig(:data, :relatedPartyDisclosureNumber),
          ).to eq 4
        end
      end

      context "when missing optional elements" do
        it "can return an empty string for address lines" do
          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "RdSAP-Schema-NI-19.0",
          )

          expect(response["data"]["addressLine2"]).to eq("")
          expect(response["data"]["addressLine3"]).to eq("")
          expect(response["data"]["addressLine4"]).to eq("")
        end

        it "can return nil for heat demand impacts" do
          doc.at("Impact-Of-Loft-Insulation").remove
          doc.at("Impact-Of-Cavity-Insulation").remove
          doc.at("Impact-Of-Solid-Wall-Insulation").remove

          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "RdSAP-Schema-NI-19.0",
          )

          expect(
            response["data"]["heatDemand"]["impactOfLoftInsulation"],
          ).to be_nil
          expect(
            response["data"]["heatDemand"]["impactOfCavityInsulation"],
          ).to be_nil
          expect(
            response["data"]["heatDemand"]["impactOfSolidWallInsulation"],
          ).to be_nil
        end

        it "can return an empty list of suggested improvements" do
          doc.at("Suggested-Improvements").remove

          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "RdSAP-Schema-NI-19.0",
          )

          expect(response["data"]["recommendedImprovements"]).to eq([])
        end
      end
    end
  end
end
