# frozen_string_literal: true

describe "Acceptance::Assessment::Lodge" do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticRdSap: "ACTIVE",
        domesticSap: "INACTIVE",
        nonDomesticCc4: "INACTIVE",
        nonDomesticSp3: "INACTIVE",
        nonDomesticDec: "STRUCKOFF",
        nonDomesticNos3: "INACTIVE",
        nonDomesticNos4: "INACTIVE",
        nonDomesticNos5: "SUSPENDED",
        gda: "INACTIVE",
      },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:valid_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-19.01.xml"
  end

  context "when lodging an energy assessment (post)" do
    it "rejects an assessment with a schema that does not exist" do
      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [400],
        schema_name: "MakeupSAP-19.0",
      )
    end

    context "when an assessor is not registered" do
      it "returns status 400" do
        lodge_assessment(assessment_body: valid_xml, accepted_responses: [400])
      end

      it "returns status 400 with the correct error response" do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_body: valid_xml, accepted_responses: [400],
            )
              .body,
          )

        expect(response["errors"][0]["title"]).to eq(
          "Assessor is not registered.",
        )
      end
    end

    it "returns 401 with no authentication" do
      lodge_assessment(
        assessment_body: "body", accepted_responses: [401], authenticate: false,
      )
    end

    it "returns 403 with incorrect scopes" do
      lodge_assessment(
        assessment_body: "body",
        accepted_responses: [403],
        auth_data: { scheme_ids: {} },
        scopes: %w[wrong:scope],
      )
    end

    it "returns 403 if it is being lodged by the wrong scheme" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)
      different_scheme_id = add_scheme_and_get_id("BADSCHEME")

      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [403],
        auth_data: { scheme_ids: [different_scheme_id] },
      )
    end

    it "returns status 201" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end

    it "returns json" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      response =
        lodge_assessment(
          assessment_body: valid_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
        )

      expect(response.headers["Content-Type"]).to eq("application/json")
    end

    it "returns the assessment as a hash" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
          )
            .body,
          symbolize_names: true,
        )

      expect(response[:data]).to be_a Hash
    end

    it "returns the correct scheme assessor id" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
          )
            .body,
          symbolize_names: true,
        )

      expect(response.dig(:data, :schemeAssessorId)).to eq("TEST000000")
    end

    context "when schema is not supported" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_xml }

      before do
        add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)

        assessment_id = doc.at("RRN")
        assessment_id.children = "1234-1234-1234-1234-1234"

        scheme_assessor_id = doc.at("Identification-Number")
        scheme_assessor_id.children = "TEST123456"
      end

      it "returns status 400" do
        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [400],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "unsupported",
        )
      end

      it "returns the correct error message" do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_body: doc.to_xml,
              accepted_responses: [400],
              auth_data: { scheme_ids: [scheme_id] },
              schema_name: "unsupported",
            )
              .body,
          )

        expect(response["errors"][0]["title"]).to eq("Schema is not supported.")
      end
    end

    context "when saving an assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_xml }
      let(:response) do
        JSON.parse(fetch_assessment("1234-1234-1234-1234-1234").body)
      end

      before do
        add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)

        assessment_id = doc.at("RRN")
        assessment_id.children = "1234-1234-1234-1234-1234"

        scheme_assessor_id = doc.at("Certificate-Number")
        scheme_assessor_id.children = "TEST123456"
      end

      context "when an assessment already exists with the same assessment id" do
        it "returns status 409" do
          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
          )

          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [409],
            auth_data: { scheme_ids: [scheme_id] },
          )
        end
      end
    end

    context "when rejecting an assessment" do
      it "rejects an assessment with an incorrect element" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

        doc = Nokogiri.XML valid_xml

        scheme_assessor_id = doc.at("Address")
        scheme_assessor_id.children = "<Postcode>invalid</Postcode>"

        response_body =
          JSON.parse(
            lodge_assessment(
              assessment_body: doc.to_xml, accepted_responses: [400],
            )
              .body,
          )

        expect(
          response_body["errors"][0]["title"],
        ).to include "This element is not expected."
      end

      it "rejects an assessment with invalid XML" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

        xml = valid_xml

        xml = xml.gsub("<Energy-Assessment>", "<Energy-Assessment")

        response_body =
          JSON.parse(
            lodge_assessment(assessment_body: xml, accepted_responses: [400])
              .body,
          )

        expect(
          response_body["errors"][0]["title"],
        ).to include "Invalid attribute name: <<Property-Summary>"
      end
    end
  end
end
