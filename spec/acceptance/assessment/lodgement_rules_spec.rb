describe "Acceptance::LodgementRules", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: fetch_assessor_stub.fetch_request_body(
        non_domestic_nos3: "ACTIVE",
        domestic_rd_sap: "ACTIVE",
      ),
    )

    scheme_id
  end

  context "when lodging CEPC" do
    let(:xml_doc) { Nokogiri.XML Samples.xml "CEPC-8.0.0", "cepc" }

    context "with two rules that are broken by it" do
      it "rejects the assessment" do
        xml_doc.at("//CEPC:Registration-Date").children = Date.tomorrow.to_s
        xml_doc.at("//CEPC:Issue-Date").children = (Date.today << 12 * 5).to_s

        result = lodge_assessment(
          assessment_body: xml_doc.to_xml,
          accepted_responses: [400],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )
        expect(JSON.parse(result.body, symbolize_names: true)[:errors]).to eq(
          [{ code: "DATES_CANT_BE_IN_FUTURE",
             title: "\"Inspection-Date\", \"Registration-Date\", \"Issue-Date\", \"Effective-Date\", \"OR-Availability-Date\", \"Start-Date\" and \"OR-Assessment-Start-Date\" must not be in the future" },
           { code: "DATES_CANT_BE_MORE_THAN_4_YEARS_AGO",
             title: "\"Inspection-Date\", \"Registration-Date\" and \"Issue-Date\" must not be more than 4 years ago" }],
        )
      end

      it "accepts a migrated assessment" do
        xml_doc.at("//CEPC:Registration-Date").children = Date.tomorrow.to_s
        xml_doc.at("//CEPC:Issue-Date").children = (Date.today << 12 * 5).to_s

        expect(lodge_assessment(
          assessment_body: xml_doc.to_xml,
          accepted_responses: [201],
          scopes: %w[assessment:lodge migrate:assessment],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
          schema_name: "CEPC-8.0.0",
        ).status).to eq(201)
      end
    end

    context "with one rule that is broken by it" do
      it "rejects the assessment" do
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
                  "\"Inspection-Date\", \"Registration-Date\", \"Issue-Date\", \"Effective-Date\", \"OR-Availability-Date\", \"Start-Date\" and \"OR-Assessment-Start-Date\" must not be in the future",
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

  context "when lodging DEC" do
    let(:xml_doc) { Nokogiri.XML Samples.xml "CEPC-8.0.0", "dec" }

    context "with a broken rule which cannot be over ridden" do
      it "rejects the assessment" do
        xml_doc.at("Technical-Information/Floor-Area").children = "-20"

        result =
          lodge_assessment(
            assessment_body: xml_doc.to_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "CEPC-8.0.0",
            override: true,
          )

        expect(JSON.parse(result.body, symbolize_names: true)).to eq(
          {
            errors: [
              {
                code: "INVALID_REQUEST",
                title:
                  "Lodgement rule cannot be overridden: \"Floor-Area\" must be greater than 0",
              },
            ],
          },
        )
      end

      context "with two broken rules including one which cannot be over ridden" do
        it "rejects the assessment and returns INVALID_REQUEST error" do
          # DATES_CANT_BE_IN_FUTURE can not be overridden
          xml_doc.at("Registration-Date").children = Date.tomorrow.to_s
          # NOMINATED_DATE_TOO_LATE can be overridden
          xml_doc.at("OR-Assessment-End-Date").children = "2020-05-01"
          xml_doc.at("This-Assessment/Nominated-Date").children = "2020-09-01"

          result =
            lodge_assessment(
              assessment_body: xml_doc.to_xml,
              accepted_responses: [400],
              auth_data: {
                scheme_ids: [scheme_id],
              },
              schema_name: "CEPC-8.0.0",
              override: true,
            )

          expect(JSON.parse(result.body, symbolize_names: true)[:errors]).to eq([
            { code: "INVALID_REQUEST",
              title: "Lodgement rule cannot be overridden: \"Inspection-Date\", \"Registration-Date\", \"Issue-Date\", \"Effective-Date\", \"OR-Availability-Date\", \"Start-Date\" and \"OR-Assessment-Start-Date\" must not be in the future" },
          ])
        end
      end
    end
  end

  context "when lodging RdSAP" do
    let(:xml_doc) { Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0" }

    context "when it breaks a rule" do
      it "rejects the assessment" do
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
