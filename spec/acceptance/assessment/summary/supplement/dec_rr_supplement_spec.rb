describe "Acceptance::AssessmentSummary::Supplement::DECRR", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor = AssessorStub.new.fetch_request_body(nonDomesticDec: "ACTIVE")
    add_assessor(scheme_id, "SPEC000000", assessor)

    add_address_base(uprn: "1")

    regular_assessment = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "dec+rr"))
    regular_assessment
      .css("UPRN")
      .each { |id| id.content = "RRN-0000-0000-0000-0000-0200" }
    lodge_dec_rr(regular_assessment.to_xml, scheme_id)
    @regular_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )

    second_assessment = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "dec-rr"))
    second_assessment.at("RRN").content = "0000-0000-0000-0000-0002"
    second_assessment.at("UPRN").content = "RRN-0000-0000-0000-0000-0010"
    second_assessment.at("E-Mail").remove
    second_assessment.at("Telephone-Number").remove
    lodge_dec_rr(second_assessment.to_xml, scheme_id)
    @second_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0002").body,
        symbolize_names: true,
      )

    third_assessment = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "dec-rr"))
    third_assessment.at("RRN").content = "0000-0000-0000-0000-0003"
    third_assessment.at("UPRN").remove
    lodge_dec_rr(third_assessment.to_xml, scheme_id)
    @third_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0003").body,
        symbolize_names: true,
      )
  end

  context "when getting the assessor data supplement" do
    it "adds scheme details" do
      scheme = @regular_summary.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end

    it "returns lodged email and phone values by default" do
      contact_details = @regular_summary.dig(:data, :assessor, :contactDetails)
      expect(contact_details).to eq(
        { telephone: "0555 497 2848", email: "a@b.c" },
      )
    end

    it "overrides missing assessor email and phone values with DB values" do
      expect(@second_summary.dig(:data, :assessor, :contactDetails)).to eq(
        { email: "person@person.com", telephone: "010199991010101" },
      )
    end
  end

  context "when getting the related reports" do
    it "returns an empty list when there are no related assessments" do
      expect(@regular_summary.dig(:data, :relatedAssessments)).to eq([])
    end

    context "when there is no UPRN field" do
      it "returns an empty list when there are no related assessments" do
        expect(@third_summary.dig(:data, :relatedAssessments)).to eq([])
      end
    end
  end

  context "when getting the related certificate energy band" do
    it "returns empty when there is no dual lodgement" do
      expect(
        @second_summary.dig(:data, :energyBandFromRelatedCertificate),
      ).to be_nil
    end

    it "returns the energy band from the dual lodged certificate" do
      expect(
        @regular_summary.dig(:data, :energyBandFromRelatedCertificate),
      ).to eq("a")
    end
  end
end

def lodge_dec_rr(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: {
      scheme_ids: [scheme_id],
    },
    schema_name: "CEPC-8.0.0",
  )
end
