# frozen_string_literal: true

describe "Acceptance::LodgeACICEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_cepc_acic_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/acic.xml"
  end

  context "when lodging an ACIC assessment (post)" do
    context "when an assessor is inactive" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_cepc_acic_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-8.0.0",
          ).body,
        )
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticCc4: "INACTIVE"),
        )
      end

      it "returns status 400 with the correct error response" do
        expect(response["errors"][0]["title"]).to eq("Assessor is not active.")
      end
    end

    context "when an assessor is active" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticCc4: "ACTIVE"),
        )

        lodge_assessment(
          assessment_body: valid_cepc_acic_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "accepts an assessment with type ACIC" do
        expect(response["data"]["typeOfAssessment"]).to eq("ACIC")
      end
    end

    context "when saving an (ACIC) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_cepc_acic_xml }

      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticCc4: "ACTIVE"),
        )

        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "returns the data that was lodged" do
        expected_response = {
          "addressId" => "UPRN-000000000000",
          "addressLine1" => "2 Lonely Street",
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
              "nonDomesticCc4" => "ACTIVE",
              "nonDomesticSp3" => "INACTIVE",
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
            "schemeAssessorId" => "SPEC000000",
            "searchResultsComparisonPostcode" => "",
          },
          "currentCarbonEmission" => 0.0,
          "currentEnergyEfficiencyBand" => "a",
          "currentEnergyEfficiencyRating" => 99,
          "optOut" => false,
          "dateOfAssessment" => "2020-05-04",
          "dateOfExpiry" => "2024-05-04",
          "dateRegistered" => "2020-05-04",
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
          "typeOfAssessment" => "ACIC",
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => nil,
          "recommendedImprovements" => [],
          "propertySummary" => [],
          "relatedAssessments" => [
            {
              "assessmentExpiryDate" => "2024-05-04",
              "assessmentId" => "0000-0000-0000-0000-0000",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "ACIC",
            },
          ],
          "status" => "ENTERED",
        }

        expect(response["data"]).to eq(expected_response)
      end
    end
  end

  context "when rejecting an assessment" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:doc) { Nokogiri.XML valid_cepc_acic_xml }

    before do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticCc4: "ACTIVE"),
      )

      doc.at("AC-Rated-Output").remove
    end

    it "rejects an assessment without an AC Rated Output" do
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [400],
        schema_name: "CEPC-NI-8.0.0",
      )
    end
  end
end
