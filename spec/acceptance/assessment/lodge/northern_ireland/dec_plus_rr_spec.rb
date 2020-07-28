# frozen_string_literal: true

describe "Acceptance::LodgeDEC+ARNIEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/dec+rr-ni.xml"
  end

  context "when lodging an DEC+AR assessment (post)" do
    context "when unqualified for DEC" do
      let(:scheme_id) { add_scheme_and_get_id }

      it "returns status 400 with the correct error response" do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticDec: "INACTIVE"),
        )

        response =
          JSON.parse(
            lodge_assessment(
              assessment_body: valid_xml,
              accepted_responses: [400],
              auth_data: { scheme_ids: [scheme_id] },
              schema_name: "CEPC-NI-8.0.0",
            ).body,
          )

        expect(response["errors"][0]["title"]).to eq("Assessor is not active.")
      end
    end

    it "returns status 201" do
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
    end

    context "when saving a (DEC+AR) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_xml }
      let(:response_dec) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end
      let(:response_ar) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0001").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticDec: "ACTIVE"),
        )
      end

      it "returns the data that was lodged" do
        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-NI-8.0.0",
        )

        expected_dec_response = {
          "addressId" => "UPRN-000000000001",
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
          "dateOfExpiry" => "2026-05-04",
          "dateRegistered" => "2020-05-04",
          "dwellingType" => "B1 Offices and Workshop businesses",
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
          "typeOfAssessment" => "DEC",
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => nil,
          "recommendedImprovements" => [],
          "propertySummary" => [],
          "relatedAssessments" => [
            {
              "assessmentExpiryDate" => "2026-05-04",
              "assessmentId" => "0000-0000-0000-0000-0001",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "DEC-RR",
            },
            {
              "assessmentExpiryDate" => "2026-05-04",
              "assessmentId" => "0000-0000-0000-0000-0000",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "DEC",
            },
          ],
          "status" => "ENTERED",
        }

        expect(response_dec["data"]).to eq(expected_dec_response)

        expected_ar_response = {
          "addressId" => "RRN-0000-0000-0000-0000-0000",
          "addressLine1" => "1 Lonely Street",
          "addressLine2" => "",
          "addressLine3" => "",
          "addressLine4" => "",
          "assessmentId" => "0000-0000-0000-0000-0001",
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
          "dateOfExpiry" => "2026-05-04",
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
          "relatedAssessments" => [
            {
              "assessmentExpiryDate" => "2026-05-04",
              "assessmentId" => "0000-0000-0000-0000-0001",
              "assessmentStatus" => "ENTERED",
              "assessmentType" => "DEC-RR",
            },
          ],
          "status" => "ENTERED",
        }

        expect(response_ar["data"]).to eq(expected_ar_response)
      end
    end

    context "when failing so save AR even though DEC went through" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticDec: "ACTIVE"),
        )
      end

      it "does not save any lodgement" do
        invalid_xml =
          valid_xml.gsub("0000-0000-0000-0000-0001", "0000-0000-0000-0000-0000")

        lodge_assessment(
          assessment_body: invalid_xml,
          accepted_responses: [409],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-NI-8.0.0",
        )

        fetch_assessment("0000-0000-0000-0000-0000", [404])

        fetch_assessment("0000-0000-0000-0000-0001", [404])
      end
    end
  end
end
