# frozen_string_literal: true

describe "Acceptance::AssessmentSummary::CEPC-RR" do
  include RSpecRegisterApiServiceMixin

  context "when a valid CEPC-RR 8.0.0 is lodged" do
    let(:xml_file) do
      File.read File.join Dir.pwd, "spec/fixtures/samples/cepc-rr.xml"
    end
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
      cepc_rr = Nokogiri.XML(xml_file)
      lodge_assessment(
        assessment_body: cepc_rr.to_xml,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      cepc_file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
      cepc = Nokogiri.XML(cepc_file)
      cepc.at("//CEPC:RRN").content = "0000-0000-0000-0000-1111"
      lodge_assessment(
        assessment_body: cepc.to_xml,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )
    end

    it "returns the assessment" do
      expect(response[:data]).to eq(
        {
          typeOfAssessment: "CEPC-RR",
          assessmentId: "0000-0000-0000-0000-0000",
          reportType: "4",
          dateOfExpiry: "2021-05-03",
          dateOfRegistration: "2020-05-05",
          relatedCertificate: "0000-0000-0000-0000-1111",
          relatedAssessments: [],
          address: {
            addressId: "UPRN-000000000000",
            addressLine1: "1 Lonely Street",
            addressLine2: nil,
            addressLine3: nil,
            addressLine4: nil,
            town: "Post-Town0",
            postcode: "A0 0AA",
          },
          assessor: {
            schemeAssessorId: "SPEC000000",
            name: "Mrs Report Writer",
            registeredBy: { name: "test scheme", schemeId: scheme_id },
            companyDetails: {
              name: "Joe Bloggs Ltd", address: "123 My Street, My City, AB3 4CD"
            },
          },
          shortPaybackRecommendations: [
            {
              code: "1",
              text:
                "Consider replacing T8 lamps with retrofit T5 conversion kit.",
              cO2Impact: "HIGH",
            },
            {
              code: "3",
              text:
                "Introduce HF (high frequency) ballasts for fluorescent tubes: Reduced number of fittings required.",
              cO2Impact: "LOW",
            },
          ],
          mediumPaybackRecommendations: [
            {
              code: "2",
              text: "Add optimum start/stop to the heating system.",
              cO2Impact: "MEDIUM",
            },
          ],
          longPaybackRecommendations: [
            {
              code: "3",
              text: "Consider installing an air source heat pump.",
              cO2Impact: "HIGH",
            },
          ],
          otherRecommendations: [
            { code: "4", text: "Consider installing PV.", cO2Impact: "HIGH" },
          ],
          technicalInformation: {
            floorArea: "10",
            buildingEnvironment: "Natural Ventilation Only",
            calculationTool: "Calculation-Tool0",
          },
          relatedPartyDisclosure: "Related to the owner",
          energyBandFromRelatedCertificate: "d",
        },
      )
    end

    context "with another assessment at the same address" do
      let(:second_assessment) { Nokogiri.XML xml_file }
      let(:assessment_id) { second_assessment.at "RRN" }
      let(:response) do
        JSON.parse(
          fetch_assessment_summary("1234-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      end

      before do
        assessment_id.children = "1234-0000-0000-0000-0000"

        lodge_assessment assessment_body: second_assessment.to_xml,
                         auth_data: { scheme_ids: [scheme_id] },
                         schema_name: "CEPC-8.0.0"
      end

      it "returns the expected related assessment" do
        expect(response[:data][:relatedAssessments]).to eq(
          [
            {
              assessmentId: "0000-0000-0000-0000-0000",
              assessmentStatus: "ENTERED",
              assessmentType: "CEPC-RR",
              assessmentExpiryDate: "2021-05-03",
            },
          ],
        )
      end
    end
  end
end
