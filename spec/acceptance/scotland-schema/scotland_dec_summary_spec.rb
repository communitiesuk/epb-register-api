describe "Acceptance::ScotlandDECSummary", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: fetch_assessor_stub.fetch_request_body(
        scotland_dec_and_ar: "ACTIVE",
      ),
    )

    scheme_id
  end

  let(:valid_dec_xml) { Samples.xml "DECAR-S-7.0", "dec" }
  let(:valid_cepc_xml) { Samples.xml "CEPC-S-7.1", "cepc" }

  context "when getting a DEC" do
    context "when the DEC is present" do
      before do
        xml = Nokogiri.XML valid_dec_xml.dup

        xml.css("UPRN").map(&:remove)
        lodge_scottish_assessment(
          assessment_body: xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "DECAR-S-7.0",
          migrated: true,
        )
      end

      it "returns the expected XML summary" do
        response =
          JSON.parse(
            fetch_scottish_dec_summary(assessment_id: "0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )

        expected_without_uprn = Samples.xml "DECAR-S-7.0", "dec_summary"
        expected_without_uprn.sub! "UPRN-000000000001", ""

        expect(response[:data]).to eq expected_without_uprn
      end
    end
  end

  context "when fetching an assessment that is not a DEC" do
    it "returns error 403, assessment is not a DEC" do
      lodge_scottish_assessment(
        assessment_body: valid_cepc_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-S-7.1",
        migrated: true,
      )

      response =
        JSON.parse(
          fetch_scottish_dec_summary(assessment_id: "0000-0000-0000-0000-0000", accepted_responses: [403]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment is not a DEC")
    end
  end

  context "when assessment id is malformed" do
    it "returns error 400, assessment id is not valid" do
      response =
        JSON.parse(
          fetch_scottish_dec_summary(assessment_id: "malformed-rrn", accepted_responses: [400]).body,
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
          fetch_scottish_dec_summary(assessment_id: "0000-0000-0000-0000-0000", accepted_responses: [404]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment not found")
    end
  end

  context "when assessment has been cancelled" do
    it "returns error 410, assessment not for issue" do
      lodge_scottish_assessment(
        assessment_body: valid_dec_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "DECAR-S-7.0",
        migrated: true,
      )

      JSON.parse(
        update_scottish_assessment_status(
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
          fetch_scottish_dec_summary(assessment_id: "0000-0000-0000-0000-0000", accepted_responses: [410]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment not for issue")
    end
  end
end
