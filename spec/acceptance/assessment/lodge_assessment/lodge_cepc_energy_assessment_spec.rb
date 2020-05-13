# frozen_string_literal: true

describe "Acceptance::LodgeCEPCEnergyAssessment" do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: { nonDomesticNos3: "ACTIVE" },
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
      qualifications: { nonDomesticNos3: "INACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(ACIC).xml"
  end

  context "when lodging a CEPC assessment (post)" do
    it "rejects an assessment with a schema that does not exist" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: valid_cepc_xml,
        accepted_responses: [400],
        schema_name: "Madeup-schema",
      )
    end

    context "when an assessor is not registered" do
      it "returns status 400" do
        lodge_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_body: valid_cepc_xml,
          accepted_responses: [400],
          schema_name: "CEPC-7.1",
        )
      end

      it "returns status 400 with the correct error response" do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_body: valid_cepc_xml,
              accepted_responses: [400],
              schema_name: "CEPC-7.1",
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
          add_assessor(scheme_id, "JASE000000", inactive_assessor_request_body)

          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_cepc_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
        end

        it "returns status 400 with the correct error response" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "JASE000000", inactive_assessor_request_body)

          response =
            JSON.parse(
              lodge_assessment(
                assessment_id: "0000-0000-0000-0000-0000",
                assessment_body: valid_cepc_xml,
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

      context "when unqualified for Nos3" do
        it "returns status 400" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "JASE000000", inactive_assessor_request_body)

          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_cepc_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
        end

        it "returns status 400 with the correct error response" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "JASE000000", inactive_assessor_request_body)

          response =
            JSON.parse(
              lodge_assessment(
                assessment_id: "0000-0000-0000-0000-0000",
                assessment_body: valid_cepc_xml,
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

      context "when unqualified for Nos3" do
        it "returns status 400" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "JASE000000", inactive_assessor_request_body)

          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_cepc_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
        end

        it "returns status 400 with the correct error response" do
          scheme_id = add_scheme_and_get_id
          add_assessor(scheme_id, "JASE000000", inactive_assessor_request_body)

          response =
            JSON.parse(
              lodge_assessment(
                assessment_id: "0000-0000-0000-0000-0000",
                assessment_body: valid_cepc_xml,
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

    it "returns 401 with no authentication" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: "body",
        accepted_responses: [401],
        authenticate: false,
        schema_name: "CEPC-7.1",
      )
    end

    it "returns 403 with incorrect scopes" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: "body",
        accepted_responses: [403],
        auth_data: { scheme_ids: {} },
        scopes: %w[wrong:scope],
        schema_name: "CEPC-7.1",
      )
    end

    it "returns 403 if it is being lodged by the wrong scheme" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)
      different_scheme_id = add_scheme_and_get_id("BADSCHEME")

      lodge_assessment(
        assessment_id: "123-344",
        assessment_body: valid_cepc_xml,
        accepted_responses: [403],
        auth_data: { scheme_ids: [different_scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "returns status 201" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: valid_cepc_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end
  end
end
