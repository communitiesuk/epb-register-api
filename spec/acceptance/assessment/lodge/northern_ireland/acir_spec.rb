# frozen_string_literal: true

describe "Acceptance::LodgeACIRNIEnergyAssessment" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_cepc_acir_ni_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/acir-ni.xml"
  end

  context "when lodging an ACIR-NI assessment" do
    context "when an assessor is inactive" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_cepc_acir_ni_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-NI-7.1",
          ).body,
        )
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticSp3: "INACTIVE"),
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
          fetch_assessor_stub.fetch_request_body(nonDomesticSp3: "ACTIVE"),
        )

        lodge_assessment(
          assessment_body: valid_cepc_acir_ni_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-NI-7.1",
        )
      end

      it "accepts an assessment with type ACIR" do
        expect(response["data"]["typeOfAssessment"]).to eq("ACIR")
      end
    end

    context "when saving a (ACIR-NI) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_cepc_acir_ni_xml }

      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticSp3: "ACTIVE"),
        )

        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-NI-7.1",
        )
      end

      it "returns the data that was lodged" do
        expected_response = {
          "addressId" => "RRN-0000-0000-0000-0000-0000",
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
            "schemeAssessorId" => "SPEC000000",
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
          "totalFloorArea" => 0.0,
          "town" => "Post-Town1",
          "typeOfAssessment" => "ACIR",
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => nil,
          "recommendedImprovements" => [],
          "propertySummary" => [],
        }

        expect(response["data"]).to eq(expected_response)
      end
    end
  end

  context "when rejecting an assessment" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:doc) { Nokogiri.XML valid_cepc_acir_ni_xml }

    before do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticSp3: "ACTIVE"),
      )

      doc.at("ACI-Related-Party-Disclosure").remove
    end

    it "rejects an assessment without an ACI Related-Party-Disclosure" do
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [400],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-7.1",
      )
    end
  end
end
