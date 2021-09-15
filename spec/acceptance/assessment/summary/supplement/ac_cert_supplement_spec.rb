describe "Acceptance::AssessmentSummary::Supplement::AC_CERT",
         set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let!(:scheme_id) { add_scheme_and_get_id }

  let!(:regular_summary) do
    assessor =
      AssessorStub.new.fetch_request_body(
        non_domestic_sp3: "ACTIVE",
        non_domestic_cc4: "ACTIVE",
      )
    add_assessor(scheme_id: scheme_id, assessor_id: "SPEC000000", body: assessor)

    lodge_ac_cert(Samples.xml("CEPC-8.0.0", "ac-cert+ac-report"), scheme_id)
    JSON.parse(
      fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
      symbolize_names: true,
    )
  end

  let!(:second_summary) do
    second_assessment =
      Nokogiri.XML(Samples.xml("CEPC-8.0.0", "ac-cert+ac-report"))
    second_assessment.at("RRN").content = "0000-0000-0000-0000-0002"
    second_assessment.at("UPRN").content = "RRN-0000-0000-0000-0000-0000"
    second_assessment.at("Related-RRN").content = "0000-0000-0000-0000-0003"
    second_assessment.search("RRN")[1].content = "0000-0000-0000-0000-0003"
    second_assessment.search("UPRN[1]")[1].content =
      "RRN-0000-0000-0000-0000-0000"
    second_assessment.search("Related-RRN")[1].content =
      "0000-0000-0000-0000-0002"
    second_assessment.at("E-Mail").remove
    second_assessment.at("Telephone-Number").remove
    lodge_ac_cert(second_assessment.to_xml, scheme_id)
    JSON.parse(
      fetch_assessment_summary(id: "0000-0000-0000-0000-0002").body,
      symbolize_names: true,
    )
  end

  context "when getting the assessor data supplement" do
    it "Adds scheme details" do
      scheme = regular_summary.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end

    it "Returns lodged email and phone values by default" do
      contact_details = regular_summary.dig(:data, :assessor, :contactDetails)

      expect(contact_details).to eq(
        { telephone: "07555 666777", email: "test@example.com" },
      )
    end

    it "Overrides missing assessor email and phone values with DB values" do
      expect(second_summary.dig(:data, :assessor, :contactDetails)).to eq(
        { email: "person@person.com", telephone: "010199991010101" },
      )
    end
  end

  context "when getting the related party disclosure" do
    it "returns the value lodged in the related document" do
      disclosure = regular_summary.dig(:data, :relatedPartyDisclosure)
      expect(disclosure).to eq("1")
    end
  end

  context "when there is a UPRN field" do
    it "returns a related assessment id when there is a matching UPRN" do
      related_assessments = second_summary.dig(:data, :relatedAssessments)
      expect(related_assessments.first[:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end
  end
end

def lodge_ac_cert(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: {
      scheme_ids: [scheme_id],
    },
    schema_name: "CEPC-8.0.0",
  )
end
