# frozen_string_literal: true

describe "Acceptance::AssessmentSummary::CEPC" do
  include RSpecRegisterApiServiceMixin

  context "when a valid CEPC 8.0.0 is lodged" do
    let(:xml_file) { File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml" }
    let(:assessment) { Nokogiri.XML xml_file }
    let(:scheme_id) { add_scheme_and_get_id }
    let(:response) do
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )
    end

    before do
      assessor =
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
        )

      add_assessor(scheme_id, "SPEC000000", assessor)

      assessment.at("//CEPC:UPRN").remove

      lodge_assessment(
        assessment_body: assessment.to_xml,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )
    end

    context "with another assessment at the same address" do
      let(:second_assessment) { Nokogiri.XML xml_file }
      let(:assessment_id) { second_assessment.at "//CEPC:RRN" }
      let(:address_id) { second_assessment.at "//CEPC:UPRN" }
      let(:response) do
        JSON.parse(
          fetch_assessment_summary("1234-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      end

      before do
        assessment_id.children = "1234-0000-0000-0000-0000"
        address_id.children = "RRN-0000-0000-0000-0000-0000"

        lodge_assessment assessment_body: second_assessment.to_xml,
                         auth_data: { scheme_ids: [scheme_id] },
                         schema_name: "CEPC-8.0.0"
      end

      it "returns the expected related assessment" do
        expect(response[:data][:relatedAssessments]).to eq(
          [
            {
              assessmentId: "1234-0000-0000-0000-0000",
              assessmentStatus: "ENTERED",
              assessmentType: "CEPC",
              assessmentExpiryDate: "2026-05-04",
            },
          ],
        )
      end
    end

    it "returns the assessment" do
      expect(response[:data]).to eq(
        {
          assessmentId: "0000-0000-0000-0000-0000",
          dateOfExpiry: "2026-05-04",
          reportType: "3",
          typeOfAssessment: "CEPC",
          dateOfAssessment: "2020-05-04",
          dateOfRegistration: "2020-05-04",
          address: {
            addressId: nil,
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
          relatedPartyDisclosure: "1",
          relatedRrn: "4192-1535-8427-8844-6702",
          newBuildRating: "28",
          newBuildBand: "b",
          existingBuildRating: "81",
          existingBuildBand: "d",
          energyEfficiencyRating: "80",
          currentEnergyEfficiencyBand: "d",
          assessor: {
            name: "TEST NAME BOI",
            schemeAssessorId: "SPEC000000",
            contactDetails: {
              email: "test@testscheme.com", telephone: "012345"
            },
            companyDetails: {
              name: "Joe Bloggs Ltd", address: "123 My Street, My City, AB3 4CD"
            },
            registeredBy: { name: "test scheme", schemeId: scheme_id },
          },
          relatedAssessments: [],
        },
      )
    end
  end
end
