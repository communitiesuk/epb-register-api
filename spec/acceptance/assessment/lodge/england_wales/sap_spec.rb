# frozen_string_literal: true

describe "Acceptance::LodgeSapEnergyAssessment" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
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
                assessment_body: valid_sap_xml,
                accepted_responses: [400],
                auth_data: { scheme_ids: [scheme_id] },
                schema_name: "SAP-Schema-17.1",
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
        assessment_body: valid_sap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "SAP-Schema-17.1",
      )
    end

    context "when saving a (SAP) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_sap_xml }
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
          schema_name: "SAP-Schema-17.1",
        )

        expected_response = {
          "addressId" => "UPRN-000000000000",
          "addressLine1" => "1 Some Street",
          "addressLine2" => "",
          "addressLine3" => "",
          "addressLine4" => "",
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
          "relatedPartyDisclosureNumber" => 1,
          "relatedPartyDisclosureText" => nil,
          "status" => "EXPIRED",
        }

        expect(response["data"]).to eq(expected_response)
      end

      context "when the assessment has related party disclosure text" do
        it "returns the data that was lodged" do
          related_party_number_xml = doc.dup

          related_party_number_xml.at(
            "Related-Party-Disclosure-Number",
          ).replace "<Related-Party-Disclosure-Text>test</Related-Party-Disclosure-Text>"

          lodge_assessment assessment_body: related_party_number_xml.to_xml,
                           accepted_responses: [201],
                           auth_data: { scheme_ids: [scheme_id] },
                           schema_name: "SAP-Schema-17.1"

          parsed_response =
            JSON.parse JSON.generate(response), symbolize_names: true

          expect(
            parsed_response.dig(:data, :relatedPartyDisclosureText),
          ).to eq "test"
        end
      end

      context "when an assessment is for a new build" do
        it "returns the heat demand correctly" do
          doc.at("RHI-Existing-Dwelling").remove

          renewable_heat_incentive = doc.at("Renewable-Heat-Incentive")

          new_dwelling = Nokogiri::XML::Node.new "RHI-New-Dwelling", doc
          new_dwelling.parent = renewable_heat_incentive

          space_heating = Nokogiri::XML::Node.new "Space-Heating", doc
          space_heating.children = "80"
          water_heating = Nokogiri::XML::Node.new "Water-Heating", doc
          water_heating.children = "90"

          space_heating.parent = new_dwelling
          space_heating.add_next_sibling water_heating

          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "SAP-Schema-17.1",
          )

          heat_demand = response["data"]["heatDemand"]

          expect(heat_demand["currentSpaceHeatingDemand"]).to eq 80
          expect(heat_demand["currentWaterHeatingDemand"]).to eq 90
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
            schema_name: "SAP-Schema-17.1",
          )

          expect(response["data"]["dwellingType"]).to be_nil
          expect(response["data"]["totalFloorArea"]).to be_zero
        end
      end
    end
  end
end
