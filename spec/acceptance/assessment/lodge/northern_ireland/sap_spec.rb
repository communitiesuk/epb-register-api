# frozen_string_literal: true

describe "Acceptance::LodgeSapNIEnergyAssessment" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_sap_ni_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap-ni.xml"
  end

  context "when lodging a domestic energy assessment (post)" do
    context "when an assessor is inactive" do
      context "when unqualified for SAP" do
        it "returns status 400 with the correct error response" do
          scheme_id = add_scheme_and_get_id
          add_assessor(
            scheme_id,
            "SPEC000000",
            fetch_assessor_stub.fetch_request_body(domesticSap: "INACTIVE"),
          )

          response =
            JSON.parse(
              lodge_assessment(
                assessment_body: valid_sap_ni_xml,
                accepted_responses: [400],
                auth_data: { scheme_ids: [scheme_id] },
                schema_name: "SAP-Schema-NI-17.4",
              )
                .body,
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
        fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_sap_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "SAP-Schema-NI-17.4",
      )
    end

    context "when saving a (SAP-NI) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_sap_ni_xml }
      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
        )
      end

      it "returns the data that was lodged" do
        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-NI-17.4",
        )

        expected_response = {
          "addressId" => "UPRN-000000000000",
          "addressLine1" => "2 Some Street",
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
              "domesticSap" => "ACTIVE",
              "domesticRdSap" => "INACTIVE",
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
            "impactOfCavityInsulation" => nil,
            "impactOfLoftInsulation" => nil,
            "impactOfSolidWallInsulation" => nil,
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
              "greenDealCategoryCode" => nil,
              "improvementCategory" => "1",
              "improvementCode" => "5",
              "improvementType" => "A",
              "improvementTitle" => nil,
              "improvementDescription" => nil,
              "indicativeCost" => "5",
              "sequence" => 0,
              "typicalSaving" => "0.0",
            },
            {
              "energyPerformanceRatingImprovement" => 60,
              "environmentalImpactRatingImprovement" => 64,
              "greenDealCategoryCode" => nil,
              "improvementCategory" => "2",
              "improvementCode" => "1",
              "improvementType" => "B",
              "improvementTitle" => nil,
              "improvementDescription" => nil,
              "indicativeCost" => "2",
              "sequence" => 1,
              "typicalSaving" => "0.1",
            },
          ],
          "totalFloorArea" => 10.0,
          "town" => "Post-Town2",
          "typeOfAssessment" => "SAP",
          "propertySummary" => [
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "walls",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "walls",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "roof",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "roof",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "floor",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "floor",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "windows",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "main_heating",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "main_heating",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "main_heating_controls",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "main_heating_controls",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "secondary_heating",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "hot_water",
            },
            {
              "energyEfficiencyRating" => 0,
              "environmentalEfficiencyRating" => 0,
              "name" => "lighting",
            },
          ],
          "propertyAgeBand" => nil,
          "relatedAssessments" => [
            {
              "assessmentExpiryDate" => "2016-05-04",
              "assessmentId" => "0000-0000-0000-0000-0000",
              "assessmentStatus" => "EXPIRED",
              "assessmentType" => "SAP",
            },
          ],
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => "Related-Party-Disclosure-Text0",
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
                           schema_name: "SAP-Schema-NI-17.4"

          parsed_response =
            JSON.parse JSON.generate(response), symbolize_names: true

          expect(
            parsed_response.dig(:data, :relatedPartyDisclosureNumber),
          ).to eq 4
        end
      end

      context "when an assessment is for a new build" do
        it "returns the heat demand correctly" do
          doc.at("RHI-Existing-Dwelling").remove

          renewable_heat_incentive = doc.at("Renewable-Heat-Incentive")

          new_dwelling = Nokogiri::XML::Node.new "RHI-New-Dwelling", doc
          new_dwelling.parent = renewable_heat_incentive

          space_heating = Nokogiri::XML::Node.new "Space-Heating", doc
          space_heating.children = "75"
          water_heating = Nokogiri::XML::Node.new "Water-Heating", doc
          water_heating.children = "65"

          space_heating.parent = new_dwelling
          space_heating.add_next_sibling water_heating

          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "SAP-Schema-NI-17.4",
          )

          heat_demand = response["data"]["heatDemand"]

          expect(heat_demand["currentSpaceHeatingDemand"]).to eq 75
          expect(heat_demand["currentWaterHeatingDemand"]).to eq 65
        end
      end

      context "when missing optional elements" do
        it "can return nil for property elements" do
          doc.at("Dwelling-Type").remove
          doc.at("Total-Floor-Area").remove

          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "SAP-Schema-NI-17.4",
          )

          expect(response["data"]["dwellingType"]).to be_nil
          expect(response["data"]["totalFloorArea"]).to be_zero
        end
      end
    end
  end
end
