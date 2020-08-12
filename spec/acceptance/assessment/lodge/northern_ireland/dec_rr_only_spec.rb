# frozen_string_literal: true

describe "Acceptance::LodgeDEC(AR)NIEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/dec-rr-ni.xml"
  end

  context "when lodging DEC advisory reports NI" do
    let(:response) do
      JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
    end

    it "accepts an assessment with type DEC-RR" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticDec: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-8.0.0",
      )

      expect(response["data"]["typeOfAssessment"]).to eq("DEC-RR")
    end

    it "returns the expected response" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticDec: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-8.0.0",
      )

      expected_response = {
        "addressId" => "RRN-0000-0000-0000-0000-0000",
        "addressLine1" => "1 Lonely Street",
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
          "qualifications" => {
            "domesticSap" => "INACTIVE",
            "domesticRdSap" => "INACTIVE",
            "nonDomesticCc4" => "INACTIVE",
            "nonDomesticSp3" => "INACTIVE",
            "nonDomesticDec" => "ACTIVE",
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
          "schemeAssessorId" => "SPEC000000",
          "searchResultsComparisonPostcode" => "",
        },
        "currentCarbonEmission" => 0.0,
        "currentEnergyEfficiencyBand" => "a",
        "currentEnergyEfficiencyRating" => 99,
        "optOut" => false,
        "dateOfAssessment" => "2020-05-04",
        "dateOfExpiry" => "2028-05-03",
        "dateRegistered" => "2020-05-04",
        "dwellingType" => "Property-Type0",
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
        "totalFloorArea" => 0.0,
        "town" => "Post-Town0",
        "typeOfAssessment" => "DEC-RR",
        "relatedPartyDisclosureNumber" => nil,
        "relatedPartyDisclosureText" => nil,
        "recommendedImprovements" => [],
        "propertySummary" => [],
        "relatedAssessments" => [],
        "status" => "ENTERED",
      }

      expect(response["data"]).to eq(expected_response)
    end
  end

  context "when rejecting an assessment" do
    it "rejects an assessment without a technical information" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticDec: "ACTIVE"),
      )

      doc = Nokogiri.XML valid_xml

      scheme_assessor_id = doc.at("Technical-Information")
      scheme_assessor_id.children = ""

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [400],
        schema_name: "CEPC-NI-8.0.0",
      )
    end
  end
end
