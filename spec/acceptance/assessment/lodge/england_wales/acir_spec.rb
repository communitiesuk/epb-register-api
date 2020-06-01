# frozen_string_literal: true

describe "Acceptance::LodgeACIREnergyAssessment" do
  include RSpecAssessorServiceMixin
  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticSap: "INACTIVE",
        domesticRdSap: "INACTIVE",
        nonDomesticSp3: "ACTIVE",
        nonDomesticCc4: "INACTIVE",
        nonDomesticDec: "INACTIVE",
        nonDomesticNos3: "INACTIVE",
        nonDomesticNos4: "INACTIVE",
        nonDomesticNos5: "INACTIVE",
        gda: "INACTIVE",
      },
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
      qualifications: { nonDomesticSp3: "INACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:valid_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(ACIR).xml"
  end

  context "when lodging ACIR" do
    let(:response) do
      JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
    end

    it "accepts an assessment with type ACIR" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "MOSE000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )

      expect(response["data"]["typeOfAssessment"]).to eq("ACIR")
    end

    it "returns the expected response" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "MOSE000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )

      expected_response = {
        "addressLine1" => "2 Lonely Street",
        "addressLine2" => "",
        "addressLine3" => "",
        "addressLine4" => "",
        "addressSummary" => "2 Lonely Street, Post-Town1, A0 0AA",
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
          "qualifications" => {
            "domesticSap" => "INACTIVE",
            "domesticRdSap" => "INACTIVE",
            "nonDomesticCc4" => "INACTIVE",
            "nonDomesticSp3" => "ACTIVE",
            "nonDomesticDec" => "INACTIVE",
            "nonDomesticNos3" => "INACTIVE",
            "nonDomesticNos4" => "INACTIVE",
            "nonDomesticNos5" => "INACTIVE",
            "gda" => "INACTIVE",
          },
          "address" => {},
          "companyDetails" => {},
          "registeredBy" => {
            "name" => "test scheme", "schemeId" => scheme_id
          },
          "schemeAssessorId" => "MOSE000000",
          "searchResultsComparisonPostcode" => "",
        },
        "currentCarbonEmission" => 0.0,
        "currentEnergyEfficiencyBand" => "a",
        "currentEnergyEfficiencyRating" => 99,
        "optOut" => false,
        "dateOfAssessment" => "2006-05-04",
        "dateOfExpiry" => "2006-05-04",
        "dateRegistered" => "2006-05-04",
        "dwellingType" => nil,
        "heatDemand" => {
          "currentSpaceHeatingDemand" => 0.0,
          "currentWaterHeatingDemand" => 0.0,
          "impactOfCavityInsulation" => nil,
          "impactOfLoftInsulation" => nil,
          "impactOfSolidWallInsulation" => nil,
        },
        "postcode" => "A0 0AA",
        "potentialCarbonEmission" => 0.0,
        "potentialEnergyEfficiencyBand" => "a",
        "potentialEnergyEfficiencyRating" => 99,
        "totalFloorArea" => 99.0,
        "town" => "Post-Town1",
        "typeOfAssessment" => "ACIR",
        "relatedPartyDisclosureNumber" => nil,
        "relatedPartyDisclosureText" => nil,
        "recommendedImprovements" => [],
        "propertySummary" => [],
      }

      expect(response["data"]).to eq(expected_response)
    end

    context "when an assessor is inactive" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor(scheme_id, "MOSE000000", inactive_assessor_request_body)
      end

      context "when unqualified for ACIR" do
        it "returns status 400 with the correct error response" do
          response =
            JSON.parse(
              lodge_assessment(
                assessment_body: valid_xml,
                accepted_responses: [400],
                auth_data: { scheme_ids: [scheme_id] },
                schema_name: "CEPC-7.1",
              )
                .body,
            )

          expect(response["errors"][0]["title"]).to eq(
            "Assessor is not active.",
          )
        end
      end
    end
  end

  context "when rejecting an assessment" do
    it "rejects an assessment without a ACI Related-Party-Disclosure" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "MOSE000000", valid_assessor_request_body)

      doc = Nokogiri.XML valid_xml

      scheme_assessor_id = doc.at("ACI-Related-Party-Disclosure")
      scheme_assessor_id.children = ""

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [400],
        schema_name: "CEPC-NI-7.1",
      )
    end

    it "rejects an assessment with invalid XML" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "MOSE000000", valid_assessor_request_body)

      xml = valid_xml.gsub("<Report-Header>", "<Report-Header")

      response_body =
        JSON.parse(
          lodge_assessment(
            assessment_body: xml,
            accepted_responses: [400],
            schema_name: "CEPC-NI-7.1",
          )
            .body,
        )

      expect(
        response_body["errors"][0]["title"],
      ).to include "Invalid attribute name: <<RRN>"
    end
  end
end
