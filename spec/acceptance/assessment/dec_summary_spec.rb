describe "Acceptance::DECSummary", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id,
      "SPEC000000",
      fetch_assessor_stub.fetch_request_body(
        nonDomesticDec: "ACTIVE",
        nonDomesticNos3: "ACTIVE",
      ),
    )

    scheme_id
  end

  let(:valid_dec_xml) { Samples.xml "CEPC-8.0.0", "dec" }
  let(:unsupported_dec_xml) { Samples.xml "CEPC-5.0", "dec" }
  let(:valid_cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }

  context "when getting a DEC" do
    context "when the DEC does not have a UPRN field" do
      before do
        xml = Nokogiri.XML valid_dec_xml.dup

        xml.css("UPRN").map(&:remove)

        lodge_assessment(
          assessment_body: xml.to_s,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "returns the expected XML summary" do
        response =
          JSON.parse(
            fetch_dec_summary("0000-0000-0000-0000-0000", [200]).body,
            symbolize_names: true,
          )

        expected_without_uprn = Samples.xml "CEPC-8.0.0", "dec_summary"
        expected_without_uprn.sub! "UPRN-000000000001", ""

        expect(response[:data]).to eq expected_without_uprn
      end
    end

    context "when the DEC does have a UPRN field" do
      it "returns the expected XML summary" do
        lodge_assessment(
          assessment_body: valid_dec_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )

        response =
          JSON.parse(
            fetch_dec_summary("0000-0000-0000-0000-0000", [200]).body,
            symbolize_names: true,
          )
        expect(response[:data]).to eq(Samples.xml("CEPC-8.0.0", "dec_summary"))
      end
    end

    context "when the DEC element names are explicitly namespaced with CEPC:" do
      it "returns the expected XML summary" do
        lodge_assessment(
          assessment_body:
            Samples.xml(
              "Additional-Fixtures",
              "cepc_800_dec_with_explicit_namespace",
            ),
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )

        response =
          JSON.parse(
            fetch_dec_summary("6666-7777-8888-9999-9999", [200]).body,
            symbolize_names: true,
          )

        expect(response[:data]).to eq(
          Samples.xml(
            "Additional-Fixtures",
            "cepc_800_dec_expected_summary_with_explicit_namespace",
          ),
        )
      end
    end
  end

  context "an assessment that is not a DEC" do
    it "returns error 403, assessment is not a DEC" do
      lodge_assessment(
        assessment_body: valid_cepc_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      response =
        JSON.parse(
          fetch_dec_summary("0000-0000-0000-0000-0000", [403]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment is not a DEC")
    end
  end

  context "when assessment id is malformed" do
    it "returns error 400, assessment id is not valid" do
      response =
        JSON.parse(
          fetch_dec_summary("malformed-rrn", [400]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq(
        "The requested assessment id is not valid",
      )
    end
  end

  context "when an assessment doesn't exist" do
    it "returns error 404, assessment not found" do
      response =
        JSON.parse(
          fetch_dec_summary("0000-0000-0000-0000-0000", [404]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment not found")
    end
  end

  context "when assessment has been cancelled" do
    it "returns error 410, assessment not for issue" do
      lodge_assessment(
        assessment_body: valid_dec_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      JSON.parse(
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: {
            "status": "CANCELLED",
          },
          accepted_responses: [200],
          auth_data: {
            scheme_ids: [scheme_id],
          },
        ).body,
        symbolize_names: true,
      )

      response =
        JSON.parse(
          fetch_dec_summary("0000-0000-0000-0000-0000", [410]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment not for issue")
    end
  end

  context "when the assessment is an unsupported schema" do
    it "returns error 400, assessment is unsupported" do
      lodge_assessment(
        assessment_body: unsupported_dec_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-5.0",
      )

      response =
        JSON.parse(
          fetch_dec_summary("0000-0000-0000-0000-0000", [400]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Unsupported schema type")
    end
  end
end
