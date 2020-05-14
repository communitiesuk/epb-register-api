# frozen_string_literal: true

describe "Acceptance::LodgeSapNIEnergyAssessment" do
  include RSpecAssessorServiceMixin

  let(:sap_valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: { domesticSap: "ACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:inactive_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: { domesticSap: "INACTIVE", domesticRdSap: "INACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:valid_sap_ni_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/SAP-NI-17.41.xml"
  end

  context "when lodging a domestic energy assessment (post)" do
    it "rejects an assessment with a schema that does not exist" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: valid_sap_ni_xml,
        accepted_responses: [400],
        schema_name: "MakeupSAP-19.0",
      )
    end

    context "when an assessor is not registered" do
      it "returns status 400" do
        lodge_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_body: valid_sap_ni_xml,
          accepted_responses: [400],
          schema_name: "SAP-Schema-NI-17.4",
        )
      end

      it "returns status 400 with the correct error response" do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_body: valid_sap_ni_xml,
              accepted_responses: [400],
              schema_name: "SAP-Schema-NI-17.4",
            )
              .body,
          )

        expect(response["errors"][0]["title"]).to eq(
          "Assessor is not registered.",
        )
      end
    end

    context "when an assessor is inactive" do
      context "when unqualified for SAP" do
        it "returns status 400" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "TEST000000", inactive_assessor_request_body)

          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_sap_ni_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "SAP-Schema-NI-17.4",
          )
        end

        it "returns status 400 with the correct error response" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "TEST000000", inactive_assessor_request_body)

          response =
            JSON.parse(
              lodge_assessment(
                assessment_id: "0000-0000-0000-0000-0000",
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

      context "when unqualified for RdSAP" do
        it "returns status 400" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "TEST000000", inactive_assessor_request_body)

          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_sap_ni_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "SAP-Schema-NI-17.4",
          )
        end

        it "returns status 400 with the correct error response" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "TEST000000", inactive_assessor_request_body)

          response =
            JSON.parse(
              lodge_assessment(
                assessment_id: "0000-0000-0000-0000-0000",
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

    it "returns 401 with no authentication" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: "body",
        accepted_responses: [401],
        authenticate: false,
      )
    end

    it "returns 403 with incorrect scopes" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: "body",
        accepted_responses: [403],
        auth_data: { scheme_ids: {} },
        scopes: %w[wrong:scope],
      )
    end

    it "returns 403 if it is being lodged by the wrong scheme" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)
      different_scheme_id = add_scheme_and_get_id("BADSCHEME")

      lodge_assessment(
        assessment_id: "123-344",
        assessment_body: valid_sap_ni_xml,
        accepted_responses: [403],
        auth_data: { scheme_ids: [different_scheme_id] },
        schema_name: "SAP-Schema-NI-17.4",
      )
    end

    it "returns status 201" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)

      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: valid_sap_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "SAP-Schema-NI-17.4",
      )
    end

    it "returns json" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)

      response =
        lodge_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_body: valid_sap_ni_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-NI-17.4",
        )

      expect(response.headers["Content-Type"]).to eq("application/json")
    end

    it "returns the assessment as a hash" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_sap_ni_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "SAP-Schema-NI-17.4",
          )
            .body,
          symbolize_names: true,
        )

      expect(response[:data]).to be_a Hash
    end

    it "returns the assessment with the correct keys" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_sap_ni_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "SAP-Schema-NI-17.4",
          )
            .body,
          symbolize_names: true,
        )

      expect(response[:data].keys).to match_array(
        %i[
          dateOfAssessment
          dateRegistered
          dwellingType
          typeOfAssessment
          totalFloorArea
          assessmentId
          schemeAssessorId
          addressSummary
          currentEnergyEfficiencyRating
          potentialEnergyEfficiencyRating
          currentCarbonEmission
          potentialCarbonEmission
          optOut
          postcode
          dateOfExpiry
          addressLine1
          addressLine2
          addressLine3
          addressLine4
          town
          heatDemand
          currentEnergyEfficiencyBand
          potentialEnergyEfficiencyBand
          recommendedImprovements
          propertySummary
          relatedPartyDisclosureNumber
          relatedPartyDisclosureText
        ],
      )
    end

    it "returns the correct scheme assessor id" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_sap_ni_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "SAP-Schema-NI-17.4",
          )
            .body,
          symbolize_names: true,
        )

      expect(response.dig(:data, :schemeAssessorId)).to eq("TEST000000")
    end

    context "when schema is not supported" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_sap_ni_xml }

      before do
        add_assessor(scheme_id, "TEST123456", sap_valid_assessor_request_body)

        assessment_id = doc.at("RRN")
        assessment_id.children = "1234-1234-1234-1234-1234"

        scheme_assessor_id = doc.at("Certificate-Number")
        scheme_assessor_id.children = "TEST123456"
      end

      it "returns status 400" do
        lodge_assessment(
          assessment_id: "1234-1234-1234-1234-1234",
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
              assessment_id: "1234-1234-1234-1234-1234",
              assessment_body: doc.to_xml,
              accepted_responses: [400],
              auth_data: { scheme_ids: [scheme_id] },
              schema_name: "unsupported",
            )
              .body,
          )

        expect(response["errors"][0]["title"]).to eq("Schema is not supported.")
      end
    end

    context "when saving a (SAP-NI) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_sap_ni_xml }
      let(:response) do
        JSON.parse(fetch_assessment("1234-1234-1234-1234-1234").body)
      end

      before do
        add_assessor(scheme_id, "TEST123456", sap_valid_assessor_request_body)

        assessment_id = doc.at("RRN")
        assessment_id.children = "1234-1234-1234-1234-1234"

        scheme_assessor_id = doc.at("Certificate-Number")
        scheme_assessor_id.children = "TEST123456"
      end

      it "returns the data that was lodged" do
        lodge_assessment(
          assessment_id: "1234-1234-1234-1234-1234",
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-NI-17.4",
        )

        expected_response = {
          "addressLine1" => "2 Some Street",
          "addressLine2" => "",
          "addressLine3" => "",
          "addressLine4" => "",
          "addressSummary" => "2 Some Street, Post-Town2, A0 0AA",
          "assessmentId" => "1234-1234-1234-1234-1234",
          "assessor" => {
            "contactDetails" => {
              "email" => "person@person.com",
              "telephoneNumber" => "010199991010101",
            },
            "dateOfBirth" => "1991-02-25",
            "firstName" => "Someone",
            "lastName" => "Person",
            "middleNames" => "Muddle",
            "qualifications" => {
              "domesticSap" => "ACTIVE",
              "domesticRdSap" => "INACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
            },
            "registeredBy" => {
              "name" => "test scheme", "schemeId" => scheme_id
            },
            "schemeAssessorId" => "TEST123456",
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
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => "Related-Party-Disclosure-Text0",
        }

        expect(response["data"]).to eq(expected_response)
      end

      it "can return the correct address summary of the property" do
        address_line_one = doc.search("Address-Line-1")[2]

        address_line_two = Nokogiri::XML::Node.new "Address-Line-2", doc
        address_line_two.content = "2 test street"
        address_line_one.add_next_sibling address_line_two

        address_line_three = Nokogiri::XML::Node.new "Address-Line-3", doc
        address_line_three.content = "3 test street"
        address_line_two.add_next_sibling address_line_three

        lodge_assessment(
          assessment_id: "1234-1234-1234-1234-1234",
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-NI-17.4",
        )

        expect(response["data"]["addressSummary"]).to eq(
          "2 Some Street, 2 test street, 3 test street, Post-Town2, A0 0AA",
        )
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
            assessment_id: "1234-1234-1234-1234-1234",
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
            assessment_id: "1234-1234-1234-1234-1234",
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

    context "when rejecting an assessment" do
      it "rejects an assessment without an address" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)

        doc = Nokogiri.XML valid_sap_ni_xml

        scheme_assessor_id = doc.at("Address")
        scheme_assessor_id.children = ""

        lodge_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_body: doc.to_xml,
          accepted_responses: [400],
          schema_name: "SAP-Schema-NI-17.4",
        )
      end

      it "rejects an assessment with an incorrect element" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)

        doc = Nokogiri.XML valid_sap_ni_xml

        scheme_assessor_id = doc.at("Address")
        scheme_assessor_id.children = "<Postcode>invalid</Postcode>"

        response_body =
          JSON.parse(
            lodge_assessment(
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_body: doc.to_xml,
              accepted_responses: [400],
              schema_name: "SAP-Schema-NI-17.4",
            )
              .body,
          )

        expect(
          response_body["errors"][0]["title"],
        ).to include "This element is not expected."
      end

      it "rejects an assessment with invalid XML" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "TEST000000", sap_valid_assessor_request_body)

        xml = valid_sap_ni_xml

        xml = xml.gsub("<Energy-Assessment>", "<Energy-Assessment")

        response_body =
          JSON.parse(
            lodge_assessment(
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_body: xml,
              accepted_responses: [400],
              schema_name: "SAP-Schema-NI-17.4",
            )
              .body,
          )

        expect(
          response_body["errors"][0]["title"],
        ).to include "Invalid attribute name: <<Assessment-Date>"
      end
    end
  end
end
