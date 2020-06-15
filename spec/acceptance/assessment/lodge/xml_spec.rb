# frozen_string_literal: true

describe "Acceptance::LodgeAssessment::XML" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/acic.xml"
  end

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end

  let(:valid_cepc_rr_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc+rr.xml"
  end

  let(:cleaned_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/sanitised/acic.xml"
  end

  let(:cleaned_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/sanitised/sap.xml"
  end

  def get_stored_xml(assessment_id)
    results =
      ActiveRecord::Base.connection.execute(
        "SELECT xml FROM assessments_xml WHERE assessment_id = '" +
          ActiveRecord::Base.sanitize_sql(assessment_id) +
          "'",
      )

    xml = ""
    results.each { |row| xml = row["xml"] }
    xml
  end

  let(:scheme_id) { add_scheme_and_get_id }

  context "when storing xml to the assessments_xml table" do
    it "will remove the <Formatted-Report> element" do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticCc4: "ACTIVE"),
      )
      lodge_assessment(
        assessment_body: valid_cepc_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )

      database_xml = get_stored_xml("0000-0000-0000-0000-0000")

      expect(valid_cepc_xml).to include("<Formatted-Report>")
      expect(cleaned_xml).to eq(
        '<?xml version="1.0" encoding="UTF-8"?>
' + database_xml,
      )
    end

    it "will remove the <PDF> element" do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
      )
      lodge_assessment(
        assessment_body: valid_sap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "SAP-Schema-17.1",
      )

      database_xml = get_stored_xml("0000-0000-0000-0000-0000")

      expect(valid_sap_xml).to include("<PDF>")
      expect(cleaned_sap_xml).to eq(
        '<?xml version="1.0" encoding="UTF-8"?>
' + database_xml,
      )
    end
  end

  context "when lodging XML" do
    it "returns an XML response" do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
      )
      response_xml =
        lodge_assessment(
          assessment_body: valid_sap_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-17.1",
          headers: { "Accept": "application/xml" },
        )
          .body

      parsed_response = Nokogiri.XML response_xml

      data_assessment_id =
        parsed_response.at_css("response data assessments assessment").xpath(
          "string()",
        )

      expect(data_assessment_id).to eq("0000-0000-0000-0000-0000")

      data_assessment_link =
        parsed_response.at_css("response meta links assessments assessment")
          .xpath("string()")

      expect(data_assessment_link).to eq(
        "/api/assessments/0000-0000-0000-0000-0000",
      )
    end

    context "when lodging two energy assessments" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        Nokogiri.XML lodge_assessment(
          assessment_body: valid_cepc_rr_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-7.1",
          headers: { "Accept": "application/xml" },
        )
                       .body
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
