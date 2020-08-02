# frozen_string_literal: true

describe "Acceptance::LodgeRREnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:cepc_rr_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc-rr.xml"
  end

  context "when lodging a RR assessment (post)" do
    let(:scheme_id) { add_scheme_and_get_id }

    it "rejects a lodgement from an unqualified assessor" do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(
          nonDomesticNos3: "INACTIVE",
          nonDomesticNos4: "INACTIVE",
          nonDomesticNos5: "INACTIVE",
        ),
      )
      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: cepc_rr_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-8.0.0",
          ).body,
        )

      expect(response["errors"][0]["title"]).to eq("Assessor is not active.")
    end

    it "successfully lodges the report" do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(
          nonDomesticNos3: "ACTIVE", nonDomesticNos4: "ACTIVE",
        ),
      )

      lodge_assessment(
        assessment_body: cepc_rr_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      response =
        JSON.parse fetch_assessment("0000-0000-0000-0000-0000").body,
                   symbolize_names: true

      expected_response = {
        addressId: "UPRN-000000000000",
        addressLine1: "1 Lonely Street",
        addressLine2: "",
        addressLine3: "",
        addressLine4: "",
        postcode: "A0 0AA",
        assessmentId: "0000-0000-0000-0000-0000",
        assessor: {
          contactDetails: {
            email: "person@person.com", telephoneNumber: "010199991010101"
          },
          dateOfBirth: "1991-02-25",
          firstName: "Someone",
          lastName: "Person",
          middleNames: "Muddle",
          qualifications: {
            domesticSap: "INACTIVE",
            domesticRdSap: "INACTIVE",
            nonDomesticCc4: "INACTIVE",
            nonDomesticSp3: "INACTIVE",
            nonDomesticDec: "INACTIVE",
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "INACTIVE",
            gda: "INACTIVE",
          },
          address: {},
          companyDetails: {},
          registeredBy: { name: "test scheme", schemeId: scheme_id },
          schemeAssessorId: "SPEC000000",
          searchResultsComparisonPostcode: "",
        },
        optOut: false,
        dateOfAssessment: "2020-05-04",
        dateOfExpiry: "2021-05-03",
        dateRegistered: "2020-05-05",
        dwellingType: "Property-Type0",
        town: "Post-Town0",
        typeOfAssessment: "CEPC-RR",
        relatedPartyDisclosureText: "Related to the owner",
        relatedAssessments: [
          {
            assessmentExpiryDate: "2021-05-03",
            assessmentId: "0000-0000-0000-0000-0000",
            assessmentStatus: "ENTERED",
            assessmentType: "CEPC-RR",
          },
        ],
        status: "ENTERED",
      }

      expect(response[:data]).to eq(expected_response)
    end
  end
end
