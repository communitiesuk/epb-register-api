describe "Acceptance::LodgementRules", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id,
      "SPEC000000",
      fetch_assessor_stub.fetch_request_body(
        nonDomesticNos3: "ACTIVE",
        domesticRdSap: "ACTIVE",
      ),
    )

    scheme_id
  end

  context "when lodging CEPC" do
    let(:xml_doc) { Nokogiri.XML Samples.xml "CEPC-8.0.0", "cepc" }

    context "that breaks two rules" do
      it "should reject the assessment" do
        xml_doc.at("//CEPC:Registration-Date").children = Date.tomorrow.to_s
        xml_doc.at("//CEPC:Issue-Date").children = (Date.today << 12 * 5).to_s

        lodge_assessment(
          assessment_body: xml_doc.to_xml,
          accepted_responses: [400],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "should accept a migrated assessment" do
        xml_doc.at("//CEPC:Registration-Date").children = Date.tomorrow.to_s
        xml_doc.at("//CEPC:Issue-Date").children = (Date.today << 12 * 5).to_s

        lodge_assessment(
          assessment_body: xml_doc.to_xml,
          accepted_responses: [201],
          scopes: %w[assessment:lodge migrate:assessment],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
          schema_name: "CEPC-8.0.0",
        )
      end
    end

    context "that breaks one rule" do
      it "should reject the assessment" do
        xml_doc.at("//CEPC:Registration-Date").children = Date.tomorrow.to_s

        result =
          lodge_assessment(
            assessment_body: xml_doc.to_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "CEPC-8.0.0",
          )

        expect(JSON.parse(result.body, symbolize_names: true)).to eq(
          {
            errors: [
              {
                code: "DATES_CANT_BE_IN_FUTURE",
                title:
                  "Inspection-Date\", \"Registration-Date\", \"Issue-Date\", \"Effective-Date\", \"OR-Availability-Date\", \"Start-Date\" and \"OR-Assessment-Start-Date\" must not be in the future",
              },
            ],
            meta: {
              links: {
                override: "/api/assessments?override=true",
              },
            },
          },
        )
      end
    end
  end

  context "when lodging RdSAP" do
    let(:xml_doc) { Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0" }

    context "that breaks a rule" do
      it "should reject the assessment" do
        xml_doc.at("Habitable-Room-Count").children = "0"

        response =
          lodge_assessment(
            assessment_body: xml_doc.to_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "RdSAP-Schema-20.0.0",
          )
        expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
          [
            {
              code: "MUST_HAVE_HABITABLE_ROOMS",
              title:
                "\"Habitable-Room-Count\" must be an integer and must be greater than or equal to 1",
            },
          ],
        )
      end
    end
  end
end
