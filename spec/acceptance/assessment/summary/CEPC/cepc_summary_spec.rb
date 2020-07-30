# frozen_string_literal: true

describe "Acceptance::AssessmentSummary::CEPC" do
  include RSpecRegisterApiServiceMixin

  context "when a valid CEPC 8.0.0 is lodged" do
    let(:response) do
      scheme_id = add_scheme_and_get_id
      assessor =
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
        )
      add_assessor(scheme_id, "SPEC000000", assessor)
      xml_file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
      lodge_assessment(
        assessment_body: xml_file,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )
    end

    it "returns the assessment" do
      expect(response[:data]).to eq(
        {
          assessmentId: "0000-0000-0000-0000-0000",
          dateOfExpiry: "2026-05-04",
          address: {
            addressLine1: "2 Lonely Street",
            addressLine2: nil,
            addressLine3: nil,
            addressLine4: nil,
            town: "Post-Town1",
            postcode: "A0 0AA",
          },
          technicalInformation: {
            mainHeatingFuel: "Natural Gas",
            buildingEnvironment: "Air Conditioning",
            floorArea: "403",
            buildingLevel: "3",
          },
          buildingEmissionRate: "67.09",
          primaryEnergyUse: "413.22",
          relatedRrn: "4192-1535-8427-8844-6702",
          newBuildRating: "28",
          existingBuildRating: "81",
          energyEfficiencyRating: "80",
          assessor: {
            firstName: "Someone",
            lastName: "Person",
            registeredBy: {
              name: "test scheme", schemeId: 1
            },
            schemeAssessorId: "SPEC000000",
            dateOfBirth: "1991-02-25",
            contactDetails: {
              email: "person@person.com", telephoneNumber: "010199991010101"
            },
            searchResultsComparisonPostcode: "",
            address: {},
            companyDetails: {},
            qualifications: {
              domesticSap: "INACTIVE",
              domesticRdSap: "INACTIVE",
              nonDomesticSp3: "INACTIVE",
              nonDomesticCc4: "INACTIVE",
              nonDomesticDec: "INACTIVE",
              nonDomesticNos3: "ACTIVE",
              nonDomesticNos4: "ACTIVE",
              nonDomesticNos5: "ACTIVE",
              gda: "INACTIVE",
            },
            middleNames: "Muddle",
          },
        },
      )
    end
  end
end
