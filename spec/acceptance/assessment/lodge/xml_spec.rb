# frozen_string_literal: true

describe "Acceptance::LodgeAssessment::XML", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_cepc_xml) { Samples.xml "CEPC-8.0.0", "ac-cert" }
  let(:valid_sap_xml) { Samples.xml "SAP-Schema-18.0.0" }
  let(:valid_cepc_rr_xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }

  let(:cleaned_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/sanitised/ac-cert.xml"
  end

  let(:cleaned_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/sanitised/sap.xml"
  end

  def get_stored_xml(assessment_id)
    results =
      ActiveRecord::Base.connection.exec_query(
        "SELECT xml FROM assessments_xml WHERE assessment_id = '" +
          ActiveRecord::Base.sanitize_sql(assessment_id) + "'",
      )

    xml = ""

    results.each { |row| xml = row["xml"] }

    xml
  end

  let(:scheme_id) { add_scheme_and_get_id }

  context "when retrieving lodged xml" do
    let(:database_xml) { get_stored_xml "0000-0000-0000-0000-0000" }

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   fetch_assessor_stub.fetch_request_body(
                     nonDomesticCc4: "ACTIVE",
                     domesticSap: "ACTIVE",
                   )
    end

    context "with a SAP assessment" do
      before do
        lodge_assessment assessment_body: valid_sap_xml,
                         accepted_responses: [201],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         },
                         schema_name: "SAP-Schema-18.0.0"
      end

      it "will remove the <PDF> element" do
        expect(valid_sap_xml).to include("<PDF>")
        expect(cleaned_sap_xml).to eq(
          '<?xml version="1.0" encoding="UTF-8"?>' + "\n" + database_xml,
        )
      end
    end
  end

  context "when lodging XML" do
    let(:response) do
      Nokogiri.XML lodge_assessment(
        assessment_body: valid_sap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-18.0.0",
        headers: {
          "Accept": "application/xml",
        },
      ).body
    end

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE")
    end

    it "returns an XML response" do
      data_assessment_id =
        response
          .at_css("response data assessments assessment")
          .xpath("string()")

      expect(data_assessment_id).to eq("0000-0000-0000-0000-0000")

      data_assessment_link =
        response
          .at_css("response meta links assessments assessment")
          .xpath("string()")

      expect(data_assessment_link).to eq(
        "/api/assessments/0000-0000-0000-0000-0000",
      )
    end

    context "when lodging CEPC with RR in same document" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        Nokogiri.XML lodge_assessment(
          assessment_body: valid_cepc_rr_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
          headers: {
            "Accept": "application/xml",
          },
        ).body
      end

      before do
        add_assessor scheme_id,
                     "SPEC000000",
                     AssessorStub.new.fetch_request_body(
                       nonDomesticNos3: "ACTIVE",
                     )
      end

      it "returns the correct response" do
        data_assessment_ids =
          response.css("response data assessments assessment").map(&:text)

        expect(data_assessment_ids).to eq(
          %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
        )

        data_assessment_links =
          response.css("response meta links assessments assessment").map(&:text)

        expect(data_assessment_links).to eq(
          %w[
            /api/assessments/0000-0000-0000-0000-0000
            /api/assessments/0000-0000-0000-0000-0001
          ],
        )
      end
    end
  end
end
