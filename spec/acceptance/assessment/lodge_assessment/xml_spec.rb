# frozen_string_literal: true

describe "Acceptance::LodgeAssessment::XML" do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        nonDomesticNos3: "ACTIVE",
        nonDomesticNos4: "ACTIVE",
        nonDomesticNos5: "INACTIVE",
      },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(ACIC).xml"
  end

  let(:cleaned_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/CLEANED-CEPC-7.11(ACIC).xml"
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

  before do
    add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)
    lodge_assessment(
      assessment_body: valid_cepc_xml,
      accepted_responses: [201],
      auth_data: { scheme_ids: [scheme_id] },
      schema_name: "CEPC-7.1",
    )
  end

  context "when storing xml to the assessments_xml table" do
    it "will remove the <Formatted-Report> element" do
      database_xml = get_stored_xml("0000-0000-0000-0000-0000")

      expect(valid_cepc_xml).to include("<Formatted-Report>")
      expect(cleaned_xml).to eq(
        '<?xml version="1.0" encoding="UTF-8"?>
' + database_xml,
      )
    end

    it "will remove the <Unstructured-Data> element" do
      database_xml = get_stored_xml("0000-0000-0000-0000-0000")

      expect(valid_cepc_xml).to include("<Unstructured-Data>")
      expect(cleaned_xml).to eq(
        '<?xml version="1.0" encoding="UTF-8"?>
' + database_xml,
      )
    end

    it "will remove the <Data-Blob> element" do
      database_xml = get_stored_xml("0000-0000-0000-0000-0000")

      expect(valid_cepc_xml).to include("<Data-Blob>")
      expect(cleaned_xml).to eq(
        '<?xml version="1.0" encoding="UTF-8"?>
' + database_xml,
      )
    end

    it "will remove the <PDF> element" do
      database_xml = get_stored_xml("0000-0000-0000-0000-0000")

      expect(valid_cepc_xml).to include("<PDF>")
      expect(cleaned_xml).to eq(
        '<?xml version="1.0" encoding="UTF-8"?>
' + database_xml,
      )
    end
  end
end
