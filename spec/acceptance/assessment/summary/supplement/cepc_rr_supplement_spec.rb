describe "Acceptance::AssessmentSummary::Supplement::CEPC_RR" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor = AssessorStub.new.fetch_request_body(nonDomesticNos3: "ACTIVE")
    add_assessor(scheme_id, "SPEC000000", assessor)

    lodge_cepc_rr(Samples.xml("CEPC-8.0.0", "cepc+rr"), scheme_id)
    @regular_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )

    second_assessment = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "cepc-rr"))
    second_assessment.at("//CEPC:RRN").content = "0000-0000-0000-0000-0002"
    second_assessment.at("//CEPC:UPRN").content = "RRN-0000-0000-0000-0000-0000"
    second_assessment.at("//CEPC:E-Mail").remove
    second_assessment.at("//CEPC:Telephone-Number").remove
    lodge_cepc_rr(second_assessment.to_xml, scheme_id)
    @second_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0002").body,
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
    it "Returns an empty list when there are no related reports" do
      expect(@regular_summary.dig(:data, :relatedAssessments)).to eq([])
    end
  end

  context "when getting the related certificate energy band" do
    it "Returns empty when there is no dual lodgement" do
      expect(
        @second_summary.dig(:data, :energyBandFromRelatedCertificate),
      ).to be_nil
    end

    it "Returns the energy band from the dual lodged certificate" do
      expect(
        @regular_summary.dig(:data, :energyBandFromRelatedCertificate),
      ).to eq("d")
    end
  end
end

def lodge_cepc_rr(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: { scheme_ids: [scheme_id] },
    schema_name: "CEPC-8.0.0",
  )
end
