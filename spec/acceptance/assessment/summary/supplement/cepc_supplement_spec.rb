describe "Acceptance::AssessmentSummary::Supplement::CEPC", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor = AssessorStub.new.fetch_request_body(nonDomesticNos3: "ACTIVE")
    add_assessor(scheme_id, "SPEC000000", assessor)

    lodge_cepc(Samples.xml("CEPC-8.0.0", "cepc"), scheme_id)
    @regular_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )

    second_assessment = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "cepc"))
    second_assessment.at("//CEPC:RRN").content = "0000-0000-0000-0000-0002"
    second_assessment.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0000"
    second_assessment.at("//CEPC:E-Mail").remove
    second_assessment.at("//CEPC:Telephone-Number").remove
    lodge_cepc(second_assessment.to_xml, scheme_id)
    @second_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0002").body,
        symbolize_names: true,
      )

    third_assessment = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "cepc"))
    third_assessment.at("//CEPC:RRN").content = "0000-0000-0000-0000-0003"
    third_assessment.at("//CEPC:UPRN").remove
    lodge_cepc(third_assessment.to_xml, scheme_id)
    @third_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0003").body,
        symbolize_names: true,
      )
  end

  context "when getting the assessor data supplement" do
    it "Adds scheme details" do
      scheme = @regular_summary.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end

    it "Returns lodged email and phone values by default" do
      contact_details = @regular_summary.dig(:data, :assessor, :contactDetails)
      expect(contact_details).to eq({ telephone: "012345", email: "a@b.c" })
    end

    it "Overrides missing assessor email and phone values with DB values" do
      expect(@second_summary.dig(:data, :assessor, :contactDetails)).to eq(
        { email: "person@person.com", telephone: "010199991010101" },
      )
    end
  end

  context "when getting the related reports" do
    it "returns an empty list when there are no related reports" do
      expect(@regular_summary.dig(:data, :relatedAssessments)).to eq([])
    end

    context "when there is no UPRN field" do
      it "returns an empty list when there are no related assessments" do
        expect(@third_summary.dig(:data, :relatedAssessments)).to eq([])
      end
    end
  end
end

def lodge_cepc(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: {
      scheme_ids: [scheme_id],
    },
    schema_name: "CEPC-8.0.0",
  )
end
